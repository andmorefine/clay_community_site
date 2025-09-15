require 'rails_helper'

RSpec.describe "Follow System", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in user
  end

  describe "POST /users/:id/follow" do
    context "when not already following" do
      it "creates a follow relationship" do
        expect {
          post follow_user_path(other_user)
        }.to change { user.followed_users.count }.by(1)
        
        expect(response).to redirect_to(other_user)
        expect(flash[:notice]).to include("You are now following")
      end

      it "returns JSON response for AJAX requests" do
        post follow_user_path(other_user), headers: { 'Accept' => 'application/json' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('followed')
        expect(json_response['followers_count']).to eq(1)
      end
    end

    context "when already following" do
      before { user.follow(other_user) }

      it "does not create duplicate follow" do
        expect {
          post follow_user_path(other_user)
        }.not_to change { user.followed_users.count }
      end
    end

    context "when trying to follow self" do
      it "does not create follow relationship" do
        expect {
          post follow_user_path(user)
        }.not_to change { user.followed_users.count }
        
        expect(response).to redirect_to(user)
        expect(flash[:alert]).to include("Unable to follow user")
      end
    end
  end

  describe "DELETE /users/:id/unfollow" do
    before { user.follow(other_user) }

    it "destroys the follow relationship" do
      expect {
        delete unfollow_user_path(other_user)
      }.to change { user.followed_users.count }.by(-1)
      
      expect(response).to redirect_to(other_user)
      expect(flash[:notice]).to include("You have unfollowed")
    end

    it "returns JSON response for AJAX requests" do
      delete unfollow_user_path(other_user), headers: { 'Accept' => 'application/json' }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('unfollowed')
      expect(json_response['followers_count']).to eq(0)
    end
  end

  describe "GET /users/:id/followers" do
    let!(:follower1) { create(:user) }
    let!(:follower2) { create(:user) }

    before do
      follower1.follow(other_user)
      follower2.follow(other_user)
    end

    it "displays followers list" do
      get followers_user_path(other_user)
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(follower1.display_name)
      expect(response.body).to include(follower2.display_name)
    end

    it "works for unauthenticated users" do
      sign_out user
      get followers_user_path(other_user)
      
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /users/:id/following" do
    let!(:followed1) { create(:user) }
    let!(:followed2) { create(:user) }

    before do
      other_user.follow(followed1)
      other_user.follow(followed2)
    end

    it "displays following list" do
      get following_user_path(other_user)
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(followed1.display_name)
      expect(response.body).to include(followed2.display_name)
    end

    it "works for unauthenticated users" do
      sign_out user
      get following_user_path(other_user)
      
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /feed" do
    let!(:followed_user) { create(:user) }
    let!(:unfollowed_user) { create(:user) }
    let!(:followed_post) { create(:post, user: followed_user) }
    let!(:unfollowed_post) { create(:post, user: unfollowed_user) }

    before { user.follow(followed_user) }

    it "shows posts from followed users" do
      get feed_path
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(followed_post.title)
      expect(response.body).not_to include(unfollowed_post.title)
    end

    it "shows popular posts when not following anyone" do
      user.unfollow(followed_user)
      
      get feed_path
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("popular posts")
    end

    it "redirects unauthenticated users to login" do
      sign_out user
      get feed_path
      
      expect(response).to redirect_to(new_session_path)
    end

    it "returns JSON response for AJAX requests" do
      get feed_path, headers: { 'Accept' => 'application/json' }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['posts']).to be_an(Array)
      expect(json_response['feed_type']).to eq('following')
    end
  end

  private

  def sign_in(user)
    post session_path, params: { 
      email: user.email, 
      password: 'password123' # Use the default factory password
    }
  end

  def sign_out(user)
    delete session_path
  end
end