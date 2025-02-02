class ReturnRequest < ApplicationRecord
  belongs_to :checkout
  belongs_to :user

  STATUSES = %w[pending approved rejected completed]

  validates :reason, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :order_is_returnable

  STATUSES.each do |status_name|
    define_method "#{status_name}?" do
      status == status_name
    end
  end

  private

  def order_is_returnable
    return unless checkout


    errors.add(:base, "Only delivered orders can be returned") unless checkout.status == 'delivered'

    # if checkout.delivered_at && checkout.delivered_at < 7.days.ago
    # errors.add(:base, "Return window has expired")
    # end


    errors.add(:base, "Return already requested for this order") if checkout.return_request.present? && checkout.return_request != self
  end
end