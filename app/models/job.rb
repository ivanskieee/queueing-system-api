class Job < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze
  
  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :priority, presence: true, numericality: { greater_than: 0 }
  
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_priority, -> { order(:priority, :created_at) }
  
  before_validation :set_defaults
  
  def processing!
    update!(status: 'processing', started_at: Time.current)
  end
  
  def complete!
    update!(status: 'completed', completed_at: Time.current)
  end
  
  def fail!(error)
    update!(status: 'failed', error_message: error, completed_at: Time.current)
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
    self.priority ||= 1
  end
end