class Cart < ApplicationRecord
  belongs_to :user, validate: false
  has_many :orderables, dependent: :destroy
  has_many :products, through: :orderables
end