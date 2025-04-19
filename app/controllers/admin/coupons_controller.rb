class Admin::CouponsController < ApplicationController
  before_action :set_admin_coupon, only: %i[show edit update destroy]
  layout 'admin'

  def index
    @admin_coupons = Coupon.all
  end

  def show
  end

  def new
    @admin_coupon = Coupon.new
  end

  def edit
  end

  def create
    @admin_coupon = Coupon.new(coupon_params)
    if @admin_coupon.save
      redirect_to admin_coupon_path(@admin_coupon), notice: "Coupon was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @admin_coupon.update(coupon_params)
      redirect_to admin_coupon_path(@admin_coupon), notice: "Coupon was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @admin_coupon.destroy!
    redirect_to admin_coupons_path, status: :see_other, notice: "Coupon was successfully destroyed."
  end

  private

  def set_admin_coupon
    @admin_coupon = Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(:code, :discount, :description, :valid_from, :valid_until, :max_usage, :status)
  end
end