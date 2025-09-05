class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post_owner, only: [:edit, :update, :destroy]

  def index
    @posts = Post.published.includes(:user, :tags, images_attachments: :blob)
    
    # Search functionality
    if params[:search].present?
      search_term = params[:search].strip
      @posts = @posts.joins(:user, :tags)
                    .where("posts.title ILIKE ? OR posts.description ILIKE ? OR users.username ILIKE ? OR tags.name ILIKE ?",
                           "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%")
                    .distinct
    end
    
    # Filter by tag if specified
    if params[:tag].present?
      @posts = @posts.by_tag(params[:tag])
    end
    
    # Filter by post type if specified
    if params[:post_type].present? && params[:post_type].in?(['regular', 'tutorial'])
      @posts = @posts.where(post_type: params[:post_type])
    end
    
    # Filter by difficulty level for tutorials
    if params[:difficulty].present? && params[:difficulty].in?(['beginner', 'intermediate', 'advanced', 'expert'])
      @posts = @posts.where(difficulty_level: params[:difficulty])
    end
    
    # Filter by user if specified
    if params[:user].present?
      user = User.find_by(username: params[:user])
      @posts = @posts.where(user: user) if user
    end
    
    # Sort posts
    case params[:sort]
    when 'popular'
      @posts = @posts.popular
    when 'trending'
      # Trending: popular posts from the last 7 days
      @posts = @posts.where('posts.created_at >= ?', 7.days.ago)
                    .joins(:likes)
                    .group('posts.id')
                    .order('COUNT(likes.id) DESC, posts.created_at DESC')
    when 'oldest'
      @posts = @posts.order(created_at: :asc)
    else
      @posts = @posts.recent
    end
    
    # Pagination
    @posts = @posts.page(params[:page]).per(params[:per_page] || 12)
    
    # Additional data for filters and display
    @popular_tags = Tag.popular_tags(20)
    @total_posts_count = Post.published.count
    @current_filters = build_current_filters
    
    respond_to do |format|
      format.html
      format.json { render json: posts_json_response }
    end
  end

  def show
    @comment = Comment.new
    @related_posts = Post.published
                         .where.not(id: @post.id)
                         .joins(:tags)
                         .where(tags: { id: @post.tag_ids })
                         .distinct
                         .limit(4)
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      # Add tags if provided
      if params[:post][:tag_names].present?
        @post.add_tags(params[:post][:tag_names])
      end
      
      redirect_to @post, notice: 'Post was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      # Update tags if provided
      if params[:post][:tag_names].present?
        @post.post_tags.destroy_all
        @post.add_tags(params[:post][:tag_names])
      end
      
      redirect_to @post, notice: 'Post was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: 'Post was successfully deleted.'
  end

  def like
    liked = @post.toggle_like(current_user)
    
    respond_to do |format|
      format.json { 
        render json: { 
          liked: liked, 
          likes_count: @post.likes_count 
        } 
      }
      format.html { redirect_to @post }
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post_owner
    unless @post.user == current_user
      redirect_to posts_path, alert: 'You are not authorized to perform this action.'
    end
  end

  def post_params
    params.require(:post).permit(:title, :description, :post_type, :difficulty_level, :published, images: [])
  end

  def build_current_filters
    {
      search: params[:search],
      tag: params[:tag],
      post_type: params[:post_type],
      difficulty: params[:difficulty],
      user: params[:user],
      sort: params[:sort] || 'recent'
    }.compact
  end

  def posts_json_response
    {
      posts: @posts.map do |post|
        {
          id: post.id,
          title: post.title,
          description: post.description,
          post_type: post.post_type,
          difficulty_level: post.difficulty_level,
          user: {
            id: post.user.id,
            username: post.user.username
          },
          tags: post.tags.map(&:name),
          likes_count: post.likes_count,
          comments_count: post.comments_count,
          created_at: post.created_at,
          thumbnail_url: post.thumbnail_url,
          url: post_url(post)
        }
      end,
      pagination: {
        current_page: @posts.current_page,
        total_pages: @posts.total_pages,
        total_count: @posts.total_count,
        per_page: @posts.limit_value
      },
      filters: @current_filters
    }
  end

  def authenticate_user!
    # This will be implemented when authentication system is ready
    # For now, we'll create a simple stub
    unless user_signed_in?
      redirect_to new_user_session_path, alert: 'Please sign in to continue.'
    end
  end

  def current_user
    # This will be implemented when authentication system is ready
    # For now, return the first user or create one for testing
    @current_user ||= User.first || User.create!(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123',
      skill_level: 'beginner'
    )
  end

  def user_signed_in?
    current_user.present?
  end
end