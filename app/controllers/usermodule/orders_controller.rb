module Usermodule
  class OrdersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_order, only: [:show, :update_address, :request_return]

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
  
      if @order.status == "shipped"
        return redirect_to usermodule_orders_path(@order), alert: "Cannot modify shipped order"
      end

    
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
      @checkout = current_user.checkouts.find(params[:id])
      respond_to do |format|
        format.pdf do
          render pdf: "invoice_#{@checkout.id}",
                 template: 'usermodule/orders/invoice.pdf.erb',  # Changed this line
                 layout: 'pdf.html',
                 disposition: 'attachment',
                 page_size: 'A4',
                 margin: { top: 0, bottom: 0, left: 0, right: 0 }
        end
        format.html { redirect_to usermodule_orders_path, notice: 'Invoice download is only available in PDF format.' }
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to usermodule_orders_path, alert: 'Order not found.'
    end
    
    def complete_pending_payment
      @checkout = current_user.checkouts.find(params[:id])
      if @checkout.payment_status == 'pending'
        redirect_to new_usermodule_checkout_path(pending_checkout_id: @checkout.id)
      else
        redirect_to usermodule_orders_path, alert: 'This order cannot be completed.'
      end
    end

    
    private

    def create_return_request
      @return_request = @order.build_return_request(
        user: current_user,
        status: 'pending',
        reason: params[:reason]
      )
      @return_request.save
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
