class UsersController < ApplicationController
  allow_unauthenticated_access only: [:show]
  before_action :set_user, only: [:show]
  before_action :set_current_user_and_authorize, only: [:edit, :update]
  
  def show
    @posts = @user.posts.published.recent
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), notice: "Profile updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def set_current_user_and_authorize
    @user = current_user
    # Ensure the user can only edit their own profile
    unless params[:id].to_i == current_user.id
      redirect_to new_session_path, alert: 'Access denied.'
    end
  end
  
  def user_params
    params.require(:user).permit(:username, :bio, :skill_level, :profile_image)
  end
end
