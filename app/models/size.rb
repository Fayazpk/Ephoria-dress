class Size < ApplicationRecord
  belongs_to :product
  # belongs_to :size


  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
