class ReportsController < ApplicationController
  include Authentication
  
  before_action :require_authentication
  before_action :find_reportable, only: [:create]
  
  def create
    @report = current_user.reports.build(report_params)
    @report.reportable = @reportable
    
    if @report.save
      render json: { 
        status: 'success', 
        message: 'Report submitted successfully. Our moderation team will review it.' 
      }
    else
      render json: { 
        status: 'error', 
        errors: @report.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def report_params
    params.require(:report).permit(:reason, :description)
  end
  
  def find_reportable
    reportable_type = params[:reportable_type]
    reportable_id = params[:reportable_id]
    
    case reportable_type
    when 'Post'
      @reportable = Post.find(reportable_id)
    when 'Comment'
      @reportable = Comment.find(reportable_id)
    when 'User'
      @reportable = User.find(reportable_id)
    else
      render json: { status: 'error', message: 'Invalid reportable type' }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Content not found' }, status: :not_found
  end
end
