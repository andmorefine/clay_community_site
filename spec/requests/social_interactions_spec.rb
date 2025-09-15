require 'rails_helper'

RSpec.describe 'Social Interactions', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user, username: 'otheruser', email: 'other@example.com') }
  let(:post_record) { create(:post, user: other_user) }

  before do
    # Sign in the user for request tests
    post session_path, params: { email: user.email, password: "password123" }
  end

  describe 'POST /posts/:id/like' do
    context 'when user has not liked the post' do
      it 'creates a like and returns success' do
        expect {
          post "/posts/#{post_record.id}/like", 
               headers: { 'Accept' => 'application/json' }
        }.to change(Like, :count).by(1)

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

      it 'removes the like and returns success' do
        expect {
          post "/posts/#{post_record.id}/like", 
               headers: { 'Accept' => 'application/json' }
        }.to change(Like, :count).by(-1)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['liked']).to be false
        expect(json_response['likes_count']).to eq(0)
      end
    end
  end

  describe 'POST /posts/:post_id/comments' do
    let(:comment_params) { { comment: { content: 'Great clay work!' } } }

    it 'creates a comment and redirects to post' do
      expect {
        post "/posts/#{post_record.id}/comments", params: comment_params
      }.to change(Comment, :count).by(1)

      expect(response).to redirect_to(post_record)
      follow_redirect!
      expect(response.body).to include('Comment was successfully added')
      expect(response.body).to include('Great clay work!')
    end

    context 'with invalid comment' do
      let(:invalid_params) { { comment: { content: '' } } }

      it 'does not create comment and redirects with error' do
        expect {
          post "/posts/#{post_record.id}/comments", params: invalid_params
        }.not_to change(Comment, :count)

        expect(response).to redirect_to(post_record)
        follow_redirect!
        expect(response.body).to include('Unable to add comment')
      end
    end
  end

  describe 'DELETE /posts/:post_id/comments/:id' do
    let!(:comment) { post_record.comments.create!(user: user, content: 'My comment') }

    context 'when user owns the comment' do
      it 'deletes the comment and redirects' do
        expect {
          delete "/posts/#{post_record.id}/comments/#{comment.id}"
        }.to change(Comment, :count).by(-1)

        expect(response).to redirect_to(post_record)
        follow_redirect!
        expect(response.body).to include('Comment was successfully deleted')
      end
    end

    context 'when user does not own the comment' do
      let!(:other_comment) { post_record.comments.create!(user: other_user, content: 'Other comment') }

      it 'does not delete comment and redirects with error' do
        expect {
          delete "/posts/#{post_record.id}/comments/#{other_comment.id}"
        }.not_to change(Comment, :count)

        expect(response).to redirect_to(post_record)
        follow_redirect!
        expect(response.body).to include('You are not authorized')
      end
    end
  end

  describe 'Social interaction display' do
    before do
      # Create some likes and comments
      post_record.likes.create!(user: user)
      post_record.likes.create!(user: other_user)
      post_record.comments.create!(user: user, content: 'First comment')
      post_record.comments.create!(user: other_user, content: 'Second comment')
    end

    it 'displays correct counts on post show page' do
      get "/posts/#{post_record.id}"
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('First comment')
      expect(response.body).to include('Second comment')
      
      # Check that like count is displayed (should be 2)
      expect(response.body).to match(/data-social-likes-count-value="2"/)
    end

    it 'displays posts with interaction counts on index page' do
      get '/posts'
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include(post_record.title)
      
      # Should show comment count
      expect(response.body).to include('2') # comments count
    end
  end

  describe 'Real-time updates via AJAX' do
    it 'returns updated counts in JSON format' do
      post "/posts/#{post_record.id}/like", 
           headers: { 'Accept' => 'application/json' }
      
      expect(response.content_type).to include('application/json')
      json_response = JSON.parse(response.body)
      
      expect(json_response).to have_key('liked')
      expect(json_response).to have_key('likes_count')
      expect(json_response['liked']).to be_in([true, false])
      expect(json_response['likes_count']).to be_a(Integer)
    end
  end

  describe 'Authentication requirements' do
    before do
      allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(false)
    end

    it 'requires authentication for liking posts' do
      post "/posts/#{post_record.id}/like"
      
      expect(response).to redirect_to(new_session_path)
    end

    it 'requires authentication for commenting' do
      post "/posts/#{post_record.id}/comments", 
           params: { comment: { content: 'Test comment' } }
      
      expect(response).to redirect_to(new_session_path)
    end

    it 'requires authentication for deleting comments' do
      comment = post_record.comments.create!(user: user, content: 'Test comment')
      
      delete "/posts/#{post_record.id}/comments/#{comment.id}"
      
      expect(response).to redirect_to(new_session_path)
    end
  end
end