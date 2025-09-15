class ApplicationController < ActionController::Base  
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Make current_user available in views
  helper_method :current_user, :user_signed_in?

  private

  def authenticate_user!
    unless user_signed_in?
      redirect_to new_session_path, alert: 'Please sign in to continue.'
    end
  end

  # def current_user
  # end

  def user_signed_in?
    current_user.present?
  end
  
  def after_authentication_url
    posts_path
  end
end
