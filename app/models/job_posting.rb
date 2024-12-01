class JobPosting < ApplicationRecord
  validates :title, presence: true
  validates :location, presence: true
  validates :company, presence: true
  validates :description, presence: true
  validates :source_url, presence: true, uniqueness: true

  scope :search_by_title, ->(query) { where("title ILIKE ?", "%#{query}%") if query.present? }
  scope :search_by_location, ->(query) { where("location ILIKE ?", "%#{query}%") if query.present? }
  scope :created_between, ->(start_date, end_date) {
    where(created_at: start_date.beginning_of_day..end_date.end_of_day) if start_date.present? && end_date.present?
  }
  scope :recent_first, -> { order(created_at: :desc) }
end
