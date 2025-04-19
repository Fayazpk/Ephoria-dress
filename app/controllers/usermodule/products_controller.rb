class Usermodule::ProductsController < ApplicationController
  before_action :set_category_and_subcategory, only: [:index, :show]
  before_action :find_product, only: [:show]

  def index
    @products = @subcategory.products.order(sort_order(params[:sort]))
    @products = @products.where("base_price >= ?", params[:min_price]) if params[:min_price].present?
    @products = @products.where("base_price <= ?", params[:max_price]) if params[:max_price].present?
    @products = @products.where("name ILIKE ?", "%#{params[:query]}%") if params[:query].present?
  end

  def search
    if params[:query].present?
      render json: Product.where('name ILIKE ?', "%#{params[:query]}%").limit(10).select(:id, :name, :category_id, :subcategory_id).map { |p| { id: p.id, name: p.name, category_id: p.category_id, subcategory_id: p.subcategory_id } }
    else
      render json: []
    end
  end

  def show
    @product = @subcategory.products.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to usermodule_category_subcategory_products_path(@category, @subcategory), alert: "Product not found."
  end

  private

  SORT_OPTIONS = %w[price_asc price_desc newest discount].freeze

  def set_category_and_subcategory
    @category = Category.find_by(id: params[:category_id])
    redirect_to root_path, alert: "Category not found." unless @category
    @subcategory = @category.subcategories.find_by(id: params[:subcategory_id])
    redirect_to categories_path, alert: "Subcategory not found for the given category." unless @subcategory
  end

  def find_product
    @product = @subcategory.products.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to usermodule_category_subcategory_products_path(@category, @subcategory), alert: "Product not found."
  end

  def sort_order(option)
    case option
    when "price_asc" then { base_price: :asc }
    when "price_desc" then { base_price: :desc }
    when "newest" then { created_at: :desc }
    when "discount" then { discount_percentage: :desc }
    else { created_at: :desc }
    end
  end
end