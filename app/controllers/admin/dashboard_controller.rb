module Admin
  class DashboardController < ApplicationController
    layout 'admin'
    before_action :authenticate_admin

    def index
      @report_data = fetch_report_data
      @top_products = top_3_selling_products_this_month
      render :index
    end

    def sales_report
      start_date, end_date = get_date_range(params[:range], params[:start_date], params[:end_date])

      @report_data = {
        orders: fetch_orders(start_date, end_date).count,
        total_sales: calculate_total_sales(start_date, end_date),
        total_discount: calculate_total_discount(start_date, end_date),
        sales_by_date: group_sales_by_date(start_date, end_date)
      }

      render json: @report_data
    end

    private

    def top_3_selling_products_this_month
      start_date = Date.today.beginning_of_month
      end_date = Date.today.end_of_month

      OrderItem.joins(:checkout, :product)
               .where(checkouts: { created_at: start_date..end_date })
               .group('products.name')
               .select('products.name', 'SUM(order_items.quantity) as total_quantity')
               .order('SUM(order_items.quantity) DESC')
               .limit(3)
               .pluck('products.name')
    end

    def fetch_report_data
      start_date, end_date = get_date_range('monthly')

      {
        orders: fetch_orders(start_date, end_date),
        total_sales: calculate_total_sales(start_date, end_date),
        total_discount: calculate_total_discount(start_date, end_date),
        sales_by_date: group_sales_by_date(start_date, end_date),

        total_orders_count: Checkout.where.not(payment_status: 'pending').count,
        total_users: User.count,
        total_products: Product.count
      }
    end

    def authenticate_admin
      redirect_to new_session_path, alert: "You must be an admin to access this area" unless current_user&.admin?
    end

    def get_date_range(range, start_date = nil, end_date = nil)
      case range
      when 'daily'
        [Date.today.beginning_of_day, Date.today.end_of_day]
      when 'weekly'
        [Date.today.beginning_of_week, Date.today.end_of_week]
      when 'monthly'
        [Date.today.beginning_of_month, Date.today.end_of_month]
      when 'yearly'
        [Date.today.beginning_of_year, Date.today.end_of_year]
      when 'custom'
        [start_date.to_date.beginning_of_day, end_date.to_date.end_of_day]
      else
        [30.days.ago.beginning_of_day, Time.current]
      end
    end

    def fetch_orders(start_date, end_date)
      Checkout.select('checkouts.*')
              .where(created_at: start_date..end_date)
              .where.not(payment_status: 'pending')
              .includes(:cart)
    end

    def calculate_total_sales(start_date, end_date)
      fetch_orders(start_date, end_date).sum(:total_price)
    end

    def calculate_total_discount(start_date, end_date)
      orders = fetch_orders(start_date, end_date)
               .includes(cart: { orderables: :product })
      total_discount = 0

      orders.each do |order|
        total_discount += order.applied_coupon.present? ? calculate_coupon_discount(order) : 0


        order.cart.orderables.each do |orderable|
          original_price = orderable.product.base_price * orderable.quantity
          discounted_price = original_price * (1 - (orderable.product.discount_percentage / 100.0))
          total_discount += original_price - discounted_price
        end
      end

      total_discount
    end

    def group_sales_by_date(start_date, end_date)
      orders = fetch_orders(start_date, end_date)


      sales_data = orders.group("DATE(checkouts.created_at)").sum(:total_price)


      sales_data.transform_keys { |k| k.strftime('%Y-%m-%d') }
    end

    def calculate_coupon_discount(_order)
      0
    end
  end
end