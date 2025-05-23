module Usermodule
  class CheckoutsController < ApplicationController
    class InsufficientBalanceError < StandardError; end

    before_action :authenticate_user!
    before_action :set_cart
    before_action :ensure_cart_not_empty, except: [:razorpay_callback]
    before_action :load_addresses, only: [:new, :create]
    before_action :set_checkout, only: [:razorpay_callback, :show]

    def new
      @checkout = Checkout.new(cart: @cart, user: current_user)
      calculate_totals
    rescue StandardError => e
      handle_error('checkout initialization', e, usermodule_cart_path)
    end

    def create
      ActiveRecord::Base.transaction do
        calculate_totals
        @checkout = build_checkout
        if @checkout.save
          save_order
          case @checkout.payment_method
          when 'razorpay' then handle_razorpay_payment
          when 'wallet' then handle_wallet_payment
          else handle_cod_payment
          end
        else
          handle_failed_checkout
        end
      rescue StandardError => e
        handle_checkout_error(e)
      end
    end

    def show
      @checkout = current_user.checkouts.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_with_error('Checkout not found', usermodule_cart_path)
    end

    def razorpay_callback
      begin
        payment_data = {
          'razorpay_payment_id' => params.dig(:checkout, :razorpay_payment_id),
          'razorpay_order_id' => params.dig(:checkout, :razorpay_order_id),
          'razorpay_signature' => params.dig(:checkout, :razorpay_signature)
        }

        if payment_data.values.any?(&:blank?)
          missing = payment_data.select { |_k, v| v.blank? }.keys
          return render json: { success: false, error: "Missing required parameters: #{missing.join(', ')}" }, status: :unprocessable_entity
        end

        if @checkout.verify_razorpay_payment(payment_data)
          clear_cart
          render json: { success: true, message: "Payment successful", redirect_url: usermodule_order_path(@checkout) }
        else
          render json: { success: false, error: "Payment verification failed", messages: @checkout.errors.full_messages }, status: :unprocessable_entity
        end
      rescue => e
        render json: { success: false, error: "Payment processing failed. Please contact support." }, status: :internal_server_error
      end
    end

    def apply_coupon
      @cart = current_user.cart
      @subtotal = @cart.orderables.sum { |orderable| calculate_orderable_price(orderable) }
      @tax = (@subtotal * 0.1).round(2)
      @shipping = 10.0
      coupon_code = params[:coupon_code]

      begin
        discount = calculate_coupon_discount(coupon_code)
        if discount > 0
          render json: { success: true, message: "Coupon applied successfully", discount: discount, total: (@subtotal + @tax + @shipping - discount).round(2) }
        else
          render json: { success: false, error: "Invalid or expired coupon", total: (@subtotal + @tax + @shipping).round(2) }
        end
      rescue => e
        render json: { success: false, error: "Error applying coupon: #{e.message}", total: (@subtotal + @tax + @shipping).round(2) }
      end
    end

    private

    def save_order
      @cart.orderables.each { |orderable| @checkout.order_items.create!(product_id: orderable.product_id, product_variant_id: orderable.product_variant_id, quantity: orderable.quantity, unit_price: orderable.product.final_price, total: orderable.total, size: orderable.size) }
    end

    def handle_wallet_payment
      begin
        ActiveRecord::Base.transaction do
          wallet = current_user.wallet
          raise InsufficientBalanceError, "Insufficient wallet balance" unless wallet.balance >= @total

          wallet_transaction = wallet.wallet_transactions.build(amount: @total, transaction_type: 'debit', transaction_id: generate_transaction_id, balance_after: wallet.balance - @total, checkout: @checkout)
          if wallet_transaction.save
            wallet.update!(balance: wallet_transaction.balance_after)
            @checkout.update!(payment_status: 'completed', status: 'processing', transaction_id: wallet_transaction.transaction_id)
            clear_cart
            redirect_to usermodule_order_path(@checkout), notice: 'Order placed successfully!'
          else
            raise ActiveRecord::Rollback
          end
        end
      rescue InsufficientBalanceError => e
        redirect_to usermodule_wallet_path, alert: 'Insufficient wallet balance. Please add money to your wallet.'
      rescue StandardError => e
        redirect_to new_usermodule_checkout_path, alert: 'Payment failed. Please try again.'
      end
    end

    def set_cart
      @cart = current_user.cart
      redirect_with_error('Cart not found', root_path) unless @cart
    end

    def set_checkout
      @checkout = current_user.checkouts.find_by(id: params[:id])
      render_error("Checkout not found", :not_found) unless @checkout
    end

    def ensure_cart_not_empty
      redirect_with_error('Your cart is empty', usermodule_cart_path) if @cart.orderables.empty?
    end

    def load_addresses
      @addresses = current_user.addresses
      redirect_with_error('Please add a delivery address to continue with checkout', new_usermodule_address_path) if @addresses.empty?
    end

    def handle_razorpay_payment
      order = @checkout.create_razorpay_order
      if order
        render json: { checkout_id: @checkout.id, razorpay_order_id: order.id, amount: order.amount, currency: order.currency }
      else
        render json: { error: @checkout.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    end

    def handle_cod_payment
      process_payment
      clear_cart
      redirect_to usermodule_order_path(@checkout), notice: 'Order placed successfully!'
    end

    def process_payment
      raise 'Invalid payment method' unless valid_payment_method?
      payment_status = checkout_params[:payment_method] == 'wallet' ? 'completed' : 'pending'
      @checkout.update!(payment_status: payment_status, status: 'processing', transaction_id: generate_transaction_id)
    end

    def valid_payment_method?
      Checkout::PAYMENT_METHODS.include?(checkout_params[:payment_method].to_s.downcase)
    end

    def clear_cart
      @cart.orderables.destroy_all
    end

    def build_checkout
      Checkout.new(cart: @cart, user: current_user, address_id: checkout_params[:address_id], payment_method: checkout_params[:payment_method].to_s.downcase, total_price: calculate_final_total, status: 'pending', payment_status: 'pending')
    end

    def calculate_totals
      return unless @cart
      @subtotal = @cart.orderables.sum { |orderable| calculate_orderable_price(orderable) }
      @tax = (@subtotal * 0.1)
      @shipping = 10.0
      @discount = calculate_coupon_discount(params[:coupon_code])
      @total = (@subtotal + @tax + @shipping - @discount).round(2)
    end

    def calculate_orderable_price(orderable)
      return 0 unless orderable.product
      (orderable.product.base_price * (1 - (orderable.product.discount_percentage / 100.0)) * orderable.quantity).round(2)
    end

    def calculate_coupon_discount(code)
      return 0 unless code.present?
      coupon = Coupon.find_by(code: code.upcase, status: true)
      return 0 unless coupon && coupon.valid_from <= Date.current && coupon.valid_until >= Date.current
      (@subtotal * (coupon.discount / 100.0)).round(2)
    end

    def calculate_final_total
      (@total || 0 - @discount || 0).round(2)
    end

    def handle_failed_checkout
      flash.now[:alert] = @checkout.errors.full_messages.to_sentence
      load_addresses
      render :new, status: :unprocessable_entity
    end

    def handle_checkout_error(error)
      flash.now[:alert] = 'An error occurred. Please try again.'
      load_addresses
      render :new, status: :unprocessable_entity
    end

    def handle_error(type, error, path)
      redirect_to path, alert: 'An error occurred. Please try again.'
    end

    def redirect_with_error(message, path)
      redirect_to path, alert: message
    end

    def render_error(message, status = :unprocessable_entity)
      render json: { success: false, error: message }, status: status
    end

    def checkout_params
      params.require(:checkout).permit(:address_id, :payment_method, :coupon_code)
    end

    def generate_transaction_id
      "TXN#{Time.current.to_i}#{SecureRandom.hex(4).upcase}"
    end
  end
end