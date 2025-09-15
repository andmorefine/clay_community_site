class Appeal < ApplicationRecord
  belongs_to :user
  belongs_to :moderation_action
  belongs_to :reviewed_by, class_name: 'User', optional: true
  
  enum :status, {
    pending: 0,
    under_review: 1,
    approved: 2,
    denied: 3
  }
  
  validates :reason, presence: true, length: { maximum: 1000 }
  validates :status, presence: true
  
  # Set default status
  after_initialize :set_default_status, if: :new_record?
  
  scope :recent, -> { order(created_at: :desc) }
  scope :unresolved, -> { where(status: [:pending, :under_review]) }
  
  def resolve!(moderator, decision)
    update!(
      status: decision,
      reviewed_by: moderator,
      reviewed_at: Time.current
    )
  end
  
  private
  
  def set_default_status
    self.status ||= :pending
  end
end
