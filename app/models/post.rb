class Post < ApplicationRecord
  belongs_to :user
  has_many_attached :images
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_users, through: :likes, source: :user
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  
  # Validations
  validates :title, presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 2000 }
  validates :images, presence: true, unless: -> { Rails.env.test? }
  validates :post_type, inclusion: { in: %w[regular tutorial] }
  validates :difficulty_level, inclusion: { in: %w[beginner intermediate advanced expert] }, 
            allow_nil: true
  
  # Custom validation for tutorial posts
  validate :tutorial_must_have_difficulty_level
  
  # Enums
  enum :post_type, { regular: 0, tutorial: 1 }
  enum :difficulty_level, { beginner: 0, intermediate: 1, advanced: 2, expert: 3 }
  
  # Scopes
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { joins(:likes).group('posts.id').order('COUNT(likes.id) DESC') }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_tag, ->(tag_name) { joins(:tags).where(tags: { name: tag_name }) }
  scope :tutorials, -> { where(post_type: :tutorial) }
  scope :regular_posts, -> { where(post_type: :regular) }
  scope :from_followed_users, ->(user) { where(user_id: user.followed_users.pluck(:id)) }
  
  # Instance methods
  def likes_count
    likes.count
  end
  
  def comments_count
    comments.count
  end
  
  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end
  
  def toggle_like(user)
    return false unless user
    
    existing_like = likes.find_by(user: user)
    if existing_like
      existing_like.destroy
      return false # unliked
    else
      likes.create(user: user)
      return true # liked
    end
  end
  
  def add_tags(tag_names)
    return if tag_names.blank?
    
    tag_names = tag_names.split(',').map(&:strip) if tag_names.is_a?(String)
    
    tag_names.each do |tag_name|
      next if tag_name.blank?
      tag = Tag.find_or_create_by(name: tag_name.downcase)
      post_tags.find_or_create_by(tag: tag)
    end
  end
  
  def tag_names
    tags.pluck(:name).join(', ')
  end
  
  def primary_image
    images.attached? ? images.first : nil
  end
  
  def thumbnail_url
    return nil unless primary_image
    
    if primary_image.variable?
      Rails.application.routes.url_helpers.rails_representation_path(
        primary_image.variant(resize_to_limit: [300, 300])
      )
    else
      Rails.application.routes.url_helpers.rails_blob_path(primary_image)
    end
  end

  def medium_image_url
    return nil unless primary_image
    
    if primary_image.variable?
      Rails.application.routes.url_helpers.rails_representation_path(
        primary_image.variant(resize_to_limit: [800, 800])
      )
    else
      Rails.application.routes.url_helpers.rails_blob_path(primary_image)
    end
  end

  def full_image_url
    return nil unless primary_image
    Rails.application.routes.url_helpers.rails_blob_path(primary_image)
  end

  def image_urls
    return [] unless images.attached?
    
    images.map do |image|
      if image.variable?
        {
          thumbnail: Rails.application.routes.url_helpers.rails_representation_url(
            image.variant(resize_to_limit: [300, 300])
          ),
          medium: Rails.application.routes.url_helpers.rails_representation_url(
            image.variant(resize_to_limit: [800, 800])
          ),
          full: Rails.application.routes.url_helpers.rails_blob_url(image)
        }
      else
        url = Rails.application.routes.url_helpers.rails_blob_url(image)
        { thumbnail: url, medium: url, full: url }
      end
    end
  end
  
  private
  
  def tutorial_must_have_difficulty_level
    if tutorial? && difficulty_level.blank?
      errors.add(:difficulty_level, "must be specified for tutorial posts")
    end
  end
end