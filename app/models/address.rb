class Address < ApplicationRecord
  belongs_to :user
  belongs_to :country, optional: true
  belongs_to :state, optional: true
  belongs_to :city, optional: true

  validates :first_name, :last_name, :building_name, :street_address, :phone, presence: true
  validates :country_name, :state_name, :city_name, presence: true

  def full_address
    [
      "#{first_name} #{last_name}",
      building_name,
      street_address,
      city_name,
      state_name,
      country_name,
      phone
    ].compact.join(", ")
  end

  before_save :sync_location_names

  private

  def sync_location_names
    self.country_name ||= country&.name
    self.state_name ||= state&.name
    self.city_name ||= city&.name
  end
end