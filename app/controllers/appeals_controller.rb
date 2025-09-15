class AppealsController < ApplicationController
  include Authentication
  
  before_action :require_authentication
  before_action :find_moderation_action, only: [:create]
  before_action :find_appeal, only: [:show]
  
  def create
    @appeal = current_user.appeals.build(appeal_params)
    @appeal.moderation_action = @moderation_action
    
    if @appeal.save
      render json: { 
        status: 'success', 
        message: 'Appeal submitted successfully. Our team will review it.',
        appeal_id: @appeal.id
      }
    else
      render json: { 
        status: 'error', 
        errors: @appeal.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  def show
    unless @appeal.user == current_user || current_user.moderator?
      redirect_to root_path, alert: 'Access denied.'
      return
    end
  end
  
  def index
    @appeals = current_user.appeals.includes(:moderation_action).recent
  end
  
  private
  
  def appeal_params
    params.require(:appeal).permit(:reason)
  end
  
  def find_moderation_action
    @moderation_action = ModerationAction.find(params[:moderation_action_id])
    
    unless @moderation_action.user == current_user
      render json: { status: 'error', message: 'Access denied' }, status: :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Moderation action not found' }, status: :not_found
  end
  
  def find_appeal
    @appeal = Appeal.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Appeal not found.'
  end
end
