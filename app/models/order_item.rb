class OrderItem < ApplicationRecord
  belongs_to :checkout
  belongs_to :product
  belongs_to :product_variant

  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, :total, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :calculate_total

  private

  def calculate_total
    self.total = quantity * unit_price if quantity && unit_price
  end
end
