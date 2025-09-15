class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access
  
  def show
    @user = User.find_by_token_for!(:email_verification, params[:token])
    
    if @user.email_verified?
      redirect_to new_session_path, notice: "Email already verified. Please sign in."
    else
      @user.verify_email!
      redirect_to new_session_path, notice: "Email verified successfully! You can now sign in."
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_session_path, alert: "Email verification link is invalid or has expired."
  end
end
