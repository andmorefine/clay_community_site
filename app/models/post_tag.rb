class PostTag < ApplicationRecord
  belongs_to :post
  belongs_to :tag
  
  # Validations
  validates :post_id, uniqueness: { scope: :tag_id, message: "already has this tag" }
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_post, ->(post) { where(post: post) }
  scope :by_tag, ->(tag) { where(tag: tag) }
  
  # Instance methods
  def tag_name
    tag.name
  end
  
  def post_title
    post.title
  end
end