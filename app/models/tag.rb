class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags
  
  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false },
            length: { minimum: 1, maximum: 50 },
            format: { with: /\A[a-zA-Z0-9\-_\s]+\z/, message: "can only contain letters, numbers, hyphens, underscores, and spaces" }
  
  # Callbacks
  before_save :normalize_name
  
  # Scopes
  scope :popular, -> { joins(:posts).group('tags.id').order('COUNT(posts.id) DESC') }
  scope :alphabetical, -> { order(:name) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_posts, -> { joins(:posts).distinct }
  
  # Instance methods
  def posts_count
    posts.published.count
  end
  
  def display_name
    name.titleize
  end
  
  def to_param
    name
  end
  
  # Class methods
  def self.find_by_name(name)
    find_by(name: name.downcase.strip)
  end
  
  def self.create_or_find_by_name(name)
    normalized_name = name.downcase.strip
    find_or_create_by(name: normalized_name)
  end
  
  def self.popular_tags(limit = 10)
    joins(:posts)
      .where(posts: { published: true })
      .group('tags.id')
      .order('COUNT(posts.id) DESC')
      .limit(limit)
      .select('tags.*, COUNT(posts.id) as posts_count')
  end
  
  def self.search(query)
    if Rails.env.test?
      where("name LIKE ?", "%#{query.downcase}%")
    else
      where("name ILIKE ?", "%#{query.downcase}%")
    end
  end
  
  private
  
  def normalize_name
    self.name = name.downcase.strip if name.present?
  end
end