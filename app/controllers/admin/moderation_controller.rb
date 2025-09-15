class Admin::ModerationController < ApplicationController
  include Authentication
  
  before_action :require_authentication
  before_action :require_moderator
  
  def index
    @pending_reports = Report.unresolved.includes(:user, :reportable).recent.limit(20)
    @recent_actions = ModerationAction.includes(:user, :moderator, :target).recent.limit(10)
    @pending_appeals = Appeal.unresolved.includes(:user, :moderation_action).recent.limit(10)
  end
  
  def reports
    @reports = Report.includes(:user, :reportable, :resolved_by)
                   .order(created_at: :desc)
                   .page(params[:page])
    
    @reports = @reports.where(status: params[:status]) if params[:status].present?
  end
  
  def show_report
    @report = Report.find(params[:id])
    @reportable = @report.reportable
  end
  
  def resolve_report
    @report = Report.find(params[:id])
    action = params[:action_type]
    
    case action
    when 'dismiss'
      @report.resolve!(current_user, 'dismissed')
      render json: { status: 'success', message: 'Report dismissed' }
    when 'approve'
      @report.resolve!(current_user, 'resolved')
      handle_content_action(@report.reportable, params[:content_action])
    when 'warn_user'
      @report.resolve!(current_user, 'resolved')
      warn_user(@report.reportable.user, params[:warning_reason])
    when 'suspend_user'
      @report.resolve!(current_user, 'resolved')
      suspend_user(@report.reportable.user, params[:suspension_duration], params[:suspension_reason])
    else
      render json: { status: 'error', message: 'Invalid action' }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Report not found' }, status: :not_found
  end
  
  def appeals
    @appeals = Appeal.includes(:user, :moderation_action, :reviewed_by)
                   .order(created_at: :desc)
                   .page(params[:page])
    
    @appeals = @appeals.where(status: params[:status]) if params[:status].present?
  end
  
  def show_appeal
    @appeal = Appeal.find(params[:id])
    @moderation_action = @appeal.moderation_action
  end
  
  def resolve_appeal
    @appeal = Appeal.find(params[:id])
    decision = params[:decision]
    
    case decision
    when 'approve'
      @appeal.resolve!(current_user, 'approved')
      reverse_moderation_action(@appeal.moderation_action)
      render json: { status: 'success', message: 'Appeal approved and action reversed' }
    when 'deny'
      @appeal.resolve!(current_user, 'denied')
      render json: { status: 'success', message: 'Appeal denied' }
    else
      render json: { status: 'error', message: 'Invalid decision' }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Appeal not found' }, status: :not_found
  end
  
  def users
    @users = User.includes(:moderation_actions)
                .order(created_at: :desc)
                .page(params[:page])
    
    @users = @users.where(suspended: true) if params[:filter] == 'suspended'
    @users = @users.where('warning_count > 0') if params[:filter] == 'warned'
  end
  
  def user_actions
    @user = User.find(params[:id])
    @actions = @user.moderation_actions.includes(:moderator).recent
    @reports = Report.where(reportable: @user).includes(:user, :resolved_by).recent
  end
  
  private
  
  def require_moderator
    unless current_user.moderator?
      redirect_to root_path, alert: 'Access denied. Moderator privileges required.'
    end
  end
  
  def handle_content_action(content, action)
    case action
    when 'remove'
      if content.respond_to?(:update!)
        content.update!(published: false) if content.respond_to?(:published)
      end
      create_moderation_action(content.user, 'content_removal', 'Content removed due to policy violation', content)
      render json: { status: 'success', message: 'Report resolved and content removed' }
    when 'approve'
      create_moderation_action(content.user, 'content_approval', 'Content approved after review', content)
      render json: { status: 'success', message: 'Report resolved and content approved' }
    else
      render json: { status: 'success', message: 'Report resolved' }
    end
  end
  
  def warn_user(user, reason)
    user.add_warning!(reason, current_user)
    render json: { status: 'success', message: 'User warned and report resolved' }
  end
  
  def suspend_user(user, duration, reason)
    duration_time = case duration
                   when '1_day' then 1.day
                   when '3_days' then 3.days
                   when '1_week' then 1.week
                   when '1_month' then 1.month
                   when 'permanent' then nil
                   else 1.day
                   end
    
    user.suspend!(duration: duration_time, reason: reason, moderator: current_user)
    render json: { status: 'success', message: 'User suspended and report resolved' }
  end
  
  def reverse_moderation_action(action)
    case action.action_type
    when 'temporary_suspension', 'permanent_suspension'
      action.user.unsuspend!(moderator: current_user)
    when 'content_removal'
      if action.target.respond_to?(:update!)
        action.target.update!(published: true) if action.target.respond_to?(:published)
      end
    end
  end
  
  def create_moderation_action(user, action_type, reason, target = nil)
    ModerationAction.create!(
      user: user,
      moderator: current_user,
      action_type: action_type,
      reason: reason,
      target: target || user
    )
  end
end