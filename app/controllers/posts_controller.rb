class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy, :quick_view, :like]
  before_action :authorize_post_owner, only: [:edit, :update, :destroy]

  def index
    @posts = Post.published.includes(:user, :tags, images_attachments: :blob)
    
    # Search functionality
    if params[:search].present?
      search_term = params[:search].strip
      like_operator = Rails.env.test? ? 'LIKE' : 'ILIKE'
      @posts = @posts.joins("LEFT JOIN users ON posts.user_id = users.id")
                    .joins("LEFT JOIN post_tags ON posts.id = post_tags.post_id")
                    .joins("LEFT JOIN tags ON post_tags.tag_id = tags.id")
                    .where("posts.title #{like_operator} ? OR posts.description #{like_operator} ? OR users.username #{like_operator} ? OR tags.name #{like_operator} ?",
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
      @posts = @posts.left_joins(:likes)
                    .group('posts.id')
                    .order('COUNT(likes.id) DESC, posts.created_at DESC')
    when 'trending'
      # Trending: popular posts from the last 7 days
      @posts = @posts.where('posts.created_at >= ?', 7.days.ago)
                    .left_joins(:likes)
                    .group('posts.id')
                    .order('COUNT(likes.id) DESC, posts.created_at DESC')
    when 'oldest'
      @posts = @posts.order(created_at: :asc)
    when 'most_commented'
      @posts = @posts.left_joins(:comments)
                    .group('posts.id')
                    .order('COUNT(comments.id) DESC, posts.created_at DESC')
    else # 'recent' or default
      @posts = @posts.recent
    end
    
    # Pagination
    per_page = params[:per_page]&.to_i || 12
    per_page = [per_page, 50].min # Max 50 per page
    @posts = @posts.page(params[:page]).per(per_page)
    
    # Additional data for filters and display
    @popular_tags = Tag.popular_tags(20)
    @total_posts_count = Post.published.count
    @current_filters = build_current_filters
    @sort_options = sort_options
    
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

  def quick_view
    respond_to do |format|
      format.json do
        # Generate image URLs with request context
        thumbnail_url = nil
        medium_image_url = nil
        
        if @post.primary_image
          if @post.primary_image.variable?
            thumbnail_url = rails_representation_url(@post.primary_image.variant(resize_to_limit: [300, 300]))
            medium_image_url = rails_representation_url(@post.primary_image.variant(resize_to_limit: [800, 800]))
          else
            thumbnail_url = rails_blob_url(@post.primary_image)
            medium_image_url = rails_blob_url(@post.primary_image)
          end
        end
        
        render json: {
          id: @post.id,
          title: @post.title,
          description: @post.description,
          post_type: @post.post_type,
          difficulty_level: @post.difficulty_level,
          user: {
            id: @post.user.id,
            username: @post.user.username
          },
          tags: @post.tags.map { |tag| { id: tag.id, name: tag.name } },
          likes_count: @post.likes_count,
          comments_count: @post.comments_count,
          created_at: @post.created_at,
          thumbnail_url: thumbnail_url,
          medium_image_url: medium_image_url,
          url: post_url(@post)
        }
      end
    end
  end

  def search_suggestions
    query = params[:q]&.strip&.downcase
    
    if query.blank? || query.length < 2
      render json: { suggestions: [] }
      return
    end
    
    suggestions = []
    
    # Tag suggestions
    like_operator = Rails.env.test? || Rails.env.development? ? 'LIKE' : 'ILIKE'
    tag_suggestions = Tag.joins(:posts)
                         .where(posts: { published: true })
                         .where("tags.name #{like_operator} ?", "%#{query}%")
                         .group('tags.id')
                         .order('COUNT(posts.id) DESC')
                         .limit(3)
                         .pluck(:name, 'COUNT(posts.id)')
    
    tag_suggestions.each do |name, count|
      suggestions << {
        type: 'tag',
        text: name,
        count: count,
        url: posts_path(tag: name)
      }
    end
    
    # User suggestions
    like_operator = Rails.env.test? || Rails.env.development? ? 'LIKE' : 'ILIKE'
    user_suggestions = User.joins(:posts)
                          .where(posts: { published: true })
                          .where("username #{like_operator} ?", "%#{query}%")
                          .group('users.id')
                          .order('COUNT(posts.id) DESC')
                          .limit(2)
                          .pluck(:username, 'COUNT(posts.id)')
    
    user_suggestions.each do |username, count|
      suggestions << {
        type: 'user',
        text: username,
        count: count,
        url: posts_path(user: username)
      }
    end
    
    # Popular search terms (you could store these in a separate model)
    popular_searches = [
      'beginner tutorial',
      'advanced techniques',
      'pottery wheel',
      'hand building',
      'glazing tips',
      'firing techniques'
    ]
    
    matching_searches = popular_searches.select { |term| term.include?(query) }
    matching_searches.first(2).each do |term|
      suggestions << {
        type: 'search',
        text: term,
        count: 0,
        url: posts_path(search: term)
      }
    end
    
    render json: { suggestions: suggestions.first(6) }
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

  def sort_options
    [
      { value: 'recent', label: 'Most Recent', icon: '🕒' },
      { value: 'popular', label: 'Most Liked', icon: '❤️' },
      { value: 'trending', label: 'Trending', icon: '🔥' },
      { value: 'most_commented', label: 'Most Discussed', icon: '💬' },
      { value: 'oldest', label: 'Oldest First', icon: '📅' }
    ]
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
            username: post.user.username,
            display_name: post.user.display_name
          },
          tags: post.tags.map { |tag| { id: tag.id, name: tag.name } },
          likes_count: post.likes_count,
          comments_count: post.comments_count,
          created_at: post.created_at,
          updated_at: post.updated_at,
          thumbnail_url: post.thumbnail_url,
          medium_image_url: post.medium_image_url,
          image_urls: post.image_urls,
          url: post_url(post),
          published: post.published
        }
      end,
      pagination: {
        current_page: @posts.current_page,
        total_pages: @posts.total_pages,
        total_count: @posts.total_count,
        per_page: @posts.limit_value,
        has_next_page: @posts.next_page.present?,
        has_prev_page: @posts.prev_page.present?
      },
      filters: @current_filters,
      meta: {
        total_posts_count: @total_posts_count,
        popular_tags: @popular_tags.map { |tag| { name: tag.name, posts_count: tag.posts_count } },
        sort_options: @sort_options
      }
    }
  end


end
