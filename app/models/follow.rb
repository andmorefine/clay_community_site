class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'
  
  # Validations
  validates :follower_id, uniqueness: { scope: :followed_id, message: "is already following this user" }
  validate :cannot_follow_self
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_follower, ->(user) { where(follower: user) }
  scope :by_followed, ->(user) { where(followed: user) }
  
  # Instance methods
  def follower_name
    follower.display_name
  end
  
  def followed_name
    followed.display_name
  end
  
  private
  
  def cannot_follow_self
    if follower_id == followed_id
      errors.add(:followed, "cannot follow yourself")
    end
  end
end