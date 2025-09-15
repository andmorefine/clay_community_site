require 'rails_helper'

RSpec.describe "Reports", type: :request do
  let(:user) { create(:user) }
  let(:post) { create(:post) }

  before do
    sign_in_user(user)
  end

  describe "POST /reports" do
    let(:valid_params) do
      {
        reportable_type: 'Post',
        reportable_id: post.id,
        report: {
          reason: 'spam',
          description: 'This post contains spam content'
        }
      }
    end

    it "creates a new report" do
      expect {
        post "/reports", params: valid_params
      }.to change(Report, :count).by(1)

      expect(response).to have_http_status(:success)
      
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
      expect(json_response['message']).to include('Report submitted successfully')
    end

    it "returns error for invalid params" do
      invalid_params = valid_params.merge(report: { reason: '', description: '' })
      
      post "/reports", params: invalid_params
      
      expect(response).to have_http_status(:unprocessable_entity)
      
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('error')
      expect(json_response['errors']).to be_present
    end

    it "returns error for invalid reportable type" do
      invalid_params = valid_params.merge(reportable_type: 'InvalidType')
      
      post "/reports", params: invalid_params
      
      expect(response).to have_http_status(:bad_request)
      
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('error')
      expect(json_response['message']).to eq('Invalid reportable type')
    end

    it "requires authentication" do
      sign_out_user
      
      post "/reports", params: valid_params
      
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_session_path)
    end
  end
end
