require 'rails_helper'

RSpec.describe LikesController, type: :controller do
  let(:user) { create(:user) }
  let(:post_record) { create(:post) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:user_signed_in?).and_return(true)
  end

  describe 'POST #create' do
    context 'when user has not liked the post' do
      it 'creates a new like' do
        expect {
          post :create, params: { post_id: post_record.id }, format: :json
        }.to change(Like, :count).by(1)
      end

      it 'returns success response' do
        post :create, params: { post_id: post_record.id }, format: :json
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['liked']).to be true
        expect(json_response['likes_count']).to eq(1)
      end
    end

    context 'when user has already liked the post' do
      before do
        post_record.likes.create!(user: user)
      end

      it 'does not create a duplicate like' do
        expect {
          post :create, params: { post_id: post_record.id }, format: :json
        }.not_to change(Like, :count)
      end

      it 'returns error response' do
        post :create, params: { post_id: post_record.id }, format: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to be_present
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user has liked the post' do
      let!(:like) { post_record.likes.create!(user: user) }

      it 'removes the like' do
        expect {
          delete :destroy, params: { post_id: post_record.id, id: like.id }, format: :json
        }.to change(Like, :count).by(-1)
      end

      it 'returns success response' do
        delete :destroy, params: { post_id: post_record.id, id: like.id }, format: :json
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['liked']).to be false
        expect(json_response['likes_count']).to eq(0)
      end
    end

    context 'when user has not liked the post' do
      it 'returns error response' do
        delete :destroy, params: { post_id: post_record.id, id: 999 }, format: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to be_present
      end
    end
  end

  describe 'authentication' do
    before do
      allow(controller).to receive(:user_signed_in?).and_return(false)
    end

    it 'requires authentication for create' do
      post :create, params: { post_id: post_record.id }, format: :json
      
      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Authentication required')
    end

    it 'requires authentication for destroy' do
      delete :destroy, params: { post_id: post_record.id, id: 1 }, format: :json
      
      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Authentication required')
    end
  end
end