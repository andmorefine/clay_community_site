class ApplicationController < ActionController::Base
  # include Authentication
  
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Make current_user available in views
  helper_method :current_user, :user_signed_in?

  private

  def authenticate_user!
    # This will be implemented when authentication system is ready
    unless user_signed_in?
      redirect_to new_session_path, alert: 'Please sign in to continue.'
    end
  end

  def current_user
    # This will be implemented when authentication system is ready
    @current_user ||= User.first || User.create!(
      email: 'test@example.com',
      username: 'testuser',
      password_digest: 'password123',
      skill_level: 'beginner'
    )
  end

  def user_signed_in?
    current_user.present?
  end
end
