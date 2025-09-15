class Report < ApplicationRecord
  belongs_to :user
  belongs_to :reportable, polymorphic: true
  belongs_to :resolved_by, class_name: 'User', optional: true
  
  enum :status, {
    pending: 0,
    under_review: 1,
    resolved: 2,
    dismissed: 3
  }
  
  validates :reason, presence: true
  validates :description, presence: true, length: { maximum: 1000 }
  validates :status, presence: true
  
  # Set default status
  after_initialize :set_default_status, if: :new_record?
  
  scope :recent, -> { order(created_at: :desc) }
  scope :unresolved, -> { where(status: [:pending, :under_review]) }
  
  def resolve!(moderator, action = 'resolved')
    update!(
      status: action,
      resolved_by: moderator,
      resolved_at: Time.current
    )
  end
  
  private
  
  def set_default_status
    self.status ||= :pending
  end
end
