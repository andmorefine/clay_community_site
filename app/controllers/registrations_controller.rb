class RegistrationsController < ApplicationController
  include Authentication

  allow_unauthenticated_access
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    
    if @user.save
      @user.send_email_verification
      redirect_to new_session_path, notice: "Account created successfully! Please check your email to verify your account."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def registration_params
    params.require(:user).permit(:email, :username, :password, :password_confirmation, :bio, :skill_level)
  end
end
