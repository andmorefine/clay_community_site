class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  
  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :for_post, ->(post) { where(post: post) }
  
  # Instance methods
  def author_name
    user.display_name
  end
  
  def can_be_deleted_by?(current_user)
    return false unless current_user
    user == current_user || post.user == current_user
  end
  
  def formatted_created_at
    created_at.strftime("%B %d, %Y at %I:%M %p")
  end
  
  def time_ago
    time_diff = Time.current - created_at
    
    case time_diff
    when 0..59
      "#{time_diff.to_i} seconds ago"
    when 60..3599
      "#{(time_diff / 60).to_i} minutes ago"
    when 3600..86399
      "#{(time_diff / 3600).to_i} hours ago"
    when 86400..2591999
      "#{(time_diff / 86400).to_i} days ago"
    else
      formatted_created_at
    end
  end
end