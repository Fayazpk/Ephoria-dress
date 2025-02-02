class Banner < ApplicationRecord
  has_many_attached :images

  validates :image, presence: true
  validate :acceptable_image

  scope :active, -> { where(active: true) }

  private

  def acceptable_image
    return unless image.attached?

    errors.add(:image, "is too big") unless image.blob.byte_size <= 5.megabytes

    acceptable_types = ["image/jpeg", "image/png", "image/webp"]
    errors.add(:image, "must be a JPEG, PNG, or WebP") unless acceptable_types.include?(image.content_type)
  end
end