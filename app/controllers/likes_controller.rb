class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    @like = @post.likes.build(user: current_user)
    
    if @like.save
      render json: { 
        liked: true, 
        likes_count: @post.likes_count,
        message: 'Post liked successfully'
      }
    else
      render json: { 
        error: 'Unable to like post',
        details: @like.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @like = @post.likes.find_by(user: current_user)
    
    if @like&.destroy
      render json: { 
        liked: false, 
        likes_count: @post.likes_count,
        message: 'Post unliked successfully'
      }
    else
      render json: { 
        error: 'Unable to unlike post'
      }, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def authenticate_user!
    # Override for JSON responses
    unless user_signed_in?
      render json: { error: 'Authentication required' }, status: :unauthorized
    end
  end
end