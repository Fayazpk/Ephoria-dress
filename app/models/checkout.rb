class Checkout < ApplicationRecord
  belongs_to :cart
  belongs_to :address
  belongs_to :user
  has_one :return_request, dependent: :destroy
  has_many :order_items, dependent: :destroy

  attr_accessor :coupon_code

  PAYMENT_METHODS = %w[cod card razorpay wallet]
  PAYMENT_STATUSES = %w[pending completed cancelled failed processing]
  STATUSES = %w[pending processing shipped delivered cancelled]

  validates :payment_method, :total_price, :status, :payment_status, presence: true
  validates :total_price, numericality: { greater_than: 0 }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS, message: "is not a valid payment method" }
  validates :status, inclusion: { in: STATUSES }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }
  validate :cart_has_items, on: :create
  validate :address_belongs_to_user

  before_validation :normalize_payment_method
  before_save :calculate_total_price, if: :cart_present?
  after_create :process_checkout
  after_update :perform_action_on_status_change, if: :status_changed?

  def create_razorpay_order
    return unless payment_method == 'razorpay'
    begin
      order = Razorpay::Order.create(amount: (total_price * 100).to_i, currency: 'INR', receipt: "checkout_#{id}", payment_capture: 1, notes: { checkout_id: id, user_id: user_id })
      update(razorpay_order_id: order.id, payment_status: 'pending')
      order
    rescue Razorpay::Error => e
      errors.add(:base, "Razorpay error: #{e.message}")
      nil
    end
  end

  def verify_razorpay_payment(payment_params)
    return false unless payment_method == 'razorpay'
    return false if payment_params.values.any?(&:blank?)

    begin
      payment_verification = { razorpay_order_id: payment_params['razorpay_order_id'], razorpay_payment_id: payment_params['razorpay_payment_id'], razorpay_signature: payment_params['razorpay_signature'] }
      if Razorpay::Utility.verify_payment_signature(payment_verification)
        ActiveRecord::Base.transaction do
          update!(payment_status: 'completed', status: 'processing', razorpay_payment_id: payment_params['razorpay_payment_id'], razorpay_signature: payment_params['razorpay_signature'])
          process_successful_payment
        end
        true
      else
        errors.add(:base, "Invalid payment signature")
        false
      end
    rescue Razorpay::Error => e
      update(payment_status: 'failed')
      errors.add(:base, "Payment verification failed: #{e.message}")
      false
    rescue StandardError => e
      update(payment_status: 'failed')
      errors.add(:base, "An unexpected error occurred during payment verification")
      false
    end
  end

  def can_return?
    status == 'delivered' && return_request.nil?
  end

  def apply_coupon(code)
    return false if code.blank?
    coupon = Coupon.find_by(code: code.upcase)
    return false if coupon.nil? || !coupon.status || (coupon.valid_from && coupon.valid_from > Date.current) || (coupon.valid_until && coupon.valid_until < Date.current) || (coupon.max_usage && Checkout.where(applied_coupon: code).count >= coupon.max_usage)

    self.coupon_code = code
    self.applied_coupon = code
    calculate_total_price
    save
  end

  private

  def process_successful_payment
    ActiveRecord::Base.transaction do
      save!
      if cart.present?
        user_ref = cart.user
        cart.orderables.destroy_all
        cart.update!(status: "processed") if cart.respond_to?(:status)
        Cart.create!(user: user_ref) if user_ref.present? && user_ref.cart.nil?
      end
    end
  end

  def process_checkout
    return unless valid?
    ActiveRecord::Base.transaction do
      self.status = payment_method == 'razorpay' ? 'pending' : 'processing'
      self.payment_status = payment_method == 'cod' ? 'pending' : 'completed'
      self.transaction_id = generate_transaction_id
      save!
      unless payment_method == 'razorpay'
        new_cart = Cart.new(user: user)
        new_cart.save(validate: false)
        cart.update!(status: "processed") if cart.respond_to?(:status)
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Failed to process checkout: #{e.message}")
    raise ActiveRecord::Rollback
  end

  def cart_has_items
    errors.add(:base, "Cart cannot be empty") if cart&.orderables&.empty?
  end

  def address_belongs_to_user
    errors.add(:address_id, "is not valid") unless address_id.nil? || cart&.user&.addresses&.exists?(address_id)
  end

  def normalize_payment_method
    self.payment_method = payment_method.downcase if payment_method.present?
  end

  def calculate_total_price
    subtotal = cart.orderables.sum { |orderable| orderable.product.base_price * (1 - (orderable.product.discount_percentage / 100.0)) * orderable.quantity }
    subtotal -= (subtotal * (Coupon.find_by(code: coupon_code.upcase)&.discount || 0) / 100.0) if coupon_code.present?
    self.total_price = subtotal + (subtotal * 0.10) + 10.0
  end

  def cart_present?
    cart.present?
  end

  def generate_transaction_id
    "TXN#{Time.current.to_i}#{SecureRandom.random_number(1000000)}"
  end

  def perform_action_on_status_change
    notify_user_of_shipping if status_changed? && status == "shipped"
  end
end