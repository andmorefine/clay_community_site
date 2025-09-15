class UsersController < ApplicationController
  include Authentication

  allow_unauthenticated_access only: [:show, :followers, :following]
  before_action :set_user, only: [:show, :follow, :unfollow, :followers, :following]
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

  def follow
    if current_user.follow(@user)
      respond_to do |format|
        format.html { redirect_to @user, notice: "You are now following #{@user.display_name}!" }
        format.json { render json: { status: 'followed', followers_count: @user.followers_count } }
      end
    else
      respond_to do |format|
        format.html { redirect_to @user, alert: "Unable to follow user." }
        format.json { render json: { error: 'Unable to follow user' }, status: :unprocessable_entity }
      end
    end
  end

  def unfollow
    if current_user.unfollow(@user)
      respond_to do |format|
        format.html { redirect_to @user, notice: "You have unfollowed #{@user.display_name}." }
        format.json { render json: { status: 'unfollowed', followers_count: @user.followers_count } }
      end
    else
      respond_to do |format|
        format.html { redirect_to @user, alert: "Unable to unfollow user." }
        format.json { render json: { error: 'Unable to unfollow user' }, status: :unprocessable_entity }
      end
    end
  end

  def followers
    @followers = @user.followers.recent.page(params[:page]).per(20)
  end

  def following
    @following = @user.followed_users.recent.page(params[:page]).per(20)
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
