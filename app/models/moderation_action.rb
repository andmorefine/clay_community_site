class ModerationAction < ApplicationRecord
  belongs_to :user
  belongs_to :moderator, class_name: 'User'
  belongs_to :target, polymorphic: true
  has_many :appeals, dependent: :destroy
  
  enum :action_type, {
    warning: 'warning',
    temporary_suspension: 'temporary_suspension',
    permanent_suspension: 'permanent_suspension',
    content_removal: 'content_removal',
    content_approval: 'content_approval'
  }
  
  validates :action_type, presence: true
  validates :reason, presence: true, length: { maximum: 1000 }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  
  def active?
    expires_at.nil? || expires_at > Time.current
  end
  
  def expired?
    !active?
  end
end
