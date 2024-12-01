class JobPreference < ApplicationRecord
  belongs_to :user

  validates :keywords, presence: true
  validates :locations, presence: true

  validate :keywords_cannot_be_empty_array
  validate :locations_cannot_be_empty_array

  private

  def keywords_cannot_be_empty_array
    if keywords.present? && keywords.reject(&:blank?).empty?
      errors.add(:keywords, "can't be an empty array")
    end
  end

  def locations_cannot_be_empty_array
    if locations.present? && locations.reject(&:blank?).empty?
      errors.add(:locations, "can't be an empty array")
    end
  end
end
