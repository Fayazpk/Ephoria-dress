class Banner < ApplicationRecord
  has_many_attached :images

    validates :image, presence: true
    validate :acceptable_image
  
    scope :active, -> { where(active: true) }
  
    private
  
    def acceptable_image
      return unless image.attached?
  
      unless image.blob.byte_size <= 5.megabytes
        errors.add(:image, "is too big")
      end
  
      acceptable_types = ["image/jpeg", "image/png", "image/webp"]
      unless acceptable_types.include?(image.content_type)
        errors.add(:image, "must be a JPEG, PNG, or WebP")
      end
    end
 
end