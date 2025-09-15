class User < ApplicationRecord
  # Authentication
  has_secure_password
  
  # Token generation for email verification and password reset
  generates_token_for :email_verification, expires_in: 2.days do
    email
  end
  
  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end
  
  # Profile information
  has_one_attached :profile_image
  
  # Relationships
  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  
  # Following relationships
  has_many :follows, foreign_key: 'follower_id', dependent: :destroy
  has_many :followed_users, through: :follows, source: :followed
  has_many :reverse_follows, foreign_key: 'followed_id', class_name: 'Follow', dependent: :destroy
  has_many :followers, through: :reverse_follows, source: :follower
  
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, 
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: { case_sensitive: false },
            length: { minimum: 3, maximum: 50 },
            format: { with: /\A[a-zA-Z0-9_]+\z/, message: "can only contain letters, numbers, and underscores" }
  validates :skill_level, inclusion: { in: %w[beginner intermediate advanced expert] }
  validates :bio, length: { maximum: 500 }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
  
  # Callbacks
  before_save :downcase_email
  before_save :downcase_username
  
  # Scopes
  scope :by_skill_level, ->(level) { where(skill_level: level) }
  scope :recent, -> { order(created_at: :desc) }

  normalizes :email, with: ->(e) { e.strip.downcase }
  
  # Class methods
  def self.authenticate_by(attributes)
    user = find_by(email: attributes[:email])
    user&.authenticate(attributes[:password]) ? user : nil
  end

  # Instance methods
  def follow(user)
    return false if user == self
    follows.find_or_create_by(followed: user)
  end
  
  def unfollow(user)
    follows.find_by(followed: user)&.destroy
  end
  
  def following?(user)
    followed_users.include?(user)
  end
  
  def followers_count
    followers.count
  end
  
  def following_count
    followed_users.count
  end
  
  def posts_count
    posts.published.count
  end
  
  def display_name
    username
  end
  
  # Email verification methods
  def verify_email!
    update!(email_verified: true, email_verified_at: Time.current)
  end
  
  def email_verified?
    email_verified
  end
  
  def send_email_verification
    UserMailer.email_verification(self).deliver_later
  end
  
  private
  
  def downcase_email
    self.email = email.downcase if email.present?
  end
  
  def downcase_username
    self.username = username.downcase if username.present?
  end
end