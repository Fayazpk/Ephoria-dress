class Product < ApplicationRecord
  belongs_to :category
  belongs_to :subcategory
  has_many :discounts, dependent: :destroy
  has_many :orderables, dependent: :destroy
  has_many :carts, through: :orderables
  has_many :product_variants, dependent: :destroy
  has_many :wishlists
  has_many :wishlist_users, through: :wishlists, source: :user
  accepts_nested_attributes_for :product_variants, allow_destroy: true

  after_create :create_variant, if: :create_variant_needed?
  has_many_attached :images

  validates :name, :description, :base_price, :category, :subcategory, presence: true
  validates :base_price, numericality: { greater_than_or_equal_to: 0 }
  validates :images, presence: { message: "must have at least one image" }

  def final_price
    return base_price unless discount_percentage.present? && discount_percentage > 0
    base_price * (1 - (discount_percentage / 100.0))
  end

  private

  def create_variant_needed?
    product_variants.empty?
  end

  def create_variant
    variant = product_variants.create
    Size.all.each { |size| variant.product_variant_sizes.create(size: size, stock: 0) }
  end
end