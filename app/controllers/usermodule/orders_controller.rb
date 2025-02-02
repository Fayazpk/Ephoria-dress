module Usermodule
  class OrdersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_order, only: [:show, :update_address, :request_return]
    before_action :set_pdf_format

    def index
      @orders = current_user.checkouts
                            .order(created_at: :desc)
                            .page(params[:page])
                            .per(10)
      @selected_order = @orders.find_by(id: params[:selected_order]) || @orders.first
    end

    def show
      @checkout = current_user.checkouts.find(params[:id])
      @order_items = @order.cart.orderables
    end

    def update_address
      return redirect_to usermodule_orders_path(@order), alert: "Cannot modify shipped order" if @order.status == "shipped"

      if @order.address.update(address_params)
        redirect_to usermodule_orders_path(@order), notice: "Address updated successfully"
      else
        redirect_to usermodule_orders_path(@order), alert: "Failed to update address"
      end
    end

    def request_return
      if @order.can_return?
        if create_return_request
          redirect_to usermodule_orders_path, notice: 'Return request submitted successfully'
        else
          redirect_to usermodule_orders_path, alert: @return_request.errors.full_messages.join(', ')
        end
      else
        redirect_to usermodule_orders_path, alert: 'This order cannot be returned'
      end
    end

    def download_invoice
      @checkout = Checkout.find_by(id: params[:id], user_id: current_user.id)

      if @checkout.nil?
        redirect_to orders_path, alert: "Invoice not found."
        return
      end

      respond_to do |format|
        format.html
        format.pdf do
          render pdf: "invoice_#{@checkout.id}",
                 template: "usermodule/orders/invoice",
                 layout: "pdf",
                 disposition: "attachment"
        end
      end
    end

    def complete_pending_payment
      @checkout = current_user.checkouts.find(params[:id])
      if @checkout.payment_status == 'pending'
        begin
          payment_successful = process_payment(@checkout)

          if payment_successful
            @checkout.update(payment_status: 'completed')
            redirect_to usermodule_orders_path, notice: 'Payment completed successfully.'
          else
            redirect_to usermodule_orders_path, alert: 'Payment failed. Please try again.'
          end
        rescue StandardError => e
          redirect_to usermodule_orders_path, alert: "An error occurred: #{e.message}"
        end
      else
        redirect_to usermodule_orders_path, alert: 'This order cannot be completed.'
      end
    end

    private

    def process_payment(checkout)
      Razorpay.setup(ENV.fetch('RAZORPAY_KEY_ID', nil), ENV.fetch('RAZORPAY_KEY_SECRET', nil))

      payment_response = Razorpay::Order.create(amount: checkout.total_amount, currency: 'INR', receipt: checkout.id)

      payment_response['status'] == 'created' # This is a placeholder; implement actual payment logic
    end

    def create_return_request
      @return_request = @order.build_return_request(
        user: current_user,
        status: 'pending',
        reason: params[:reason]
      )
      @return_request.save
    end

    def set_pdf_format
      request.format = :pdf if params[:format] == 'pdf'
    end

    def set_order
      @order = current_user.checkouts.find_by(id: params[:id])
      redirect_to usermodule_orders_path, alert: "Order not found" if @order.nil?
    end

    def address_params
      params.require(:address).permit(:first_name, :last_name, :building_name,
                                      :street_address, :city_id, :state_id,
                                      :country_id, :phone)
    end
  end
end
