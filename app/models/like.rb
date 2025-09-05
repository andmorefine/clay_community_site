class Like < ApplicationRecord
  belongs_to :user
  belongs_to :post
  
  # Validations
  validates :user_id, uniqueness: { scope: :post_id, message: "has already liked this post" }
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :for_post, ->(post) { where(post: post) }
  
  # Callbacks
  after_create :increment_post_likes_counter
  after_destroy :decrement_post_likes_counter
  
  # Instance methods
  def liker_name
    user.display_name
  end
  
  private
  
  def increment_post_likes_counter
    # This could be used for caching likes count if needed
    # post.increment!(:likes_count)
  end
  
  def decrement_post_likes_counter
    # This could be used for caching likes count if needed
    # post.decrement!(:likes_count)
  end
end