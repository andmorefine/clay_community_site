require 'rails_helper'

RSpec.describe "Follow System Integration", type: :request do
  let(:alice) { create(:user, username: 'alice') }
  let(:bob) { create(:user, username: 'bob') }
  let!(:bob_post) { create(:post, user: bob, title: "Bob's Amazing Clay Bowl") }

  before do
    # Sign in Alice using session
    post session_path, params: { email: alice.email, password: 'password123' }
  end

  describe "Follow functionality" do
    it "allows users to follow and unfollow other users" do
      # Follow Bob
      post follow_user_path(bob)
      expect(response).to redirect_to(bob)
      
      # Check that follow was created
      expect(alice.following?(bob)).to be true
      expect(bob.followers_count).to eq(1)
      
      # Unfollow Bob
      delete unfollow_user_path(bob)
      expect(response).to redirect_to(bob)
      
      # Check that follow was removed
      expect(alice.following?(bob)).to be false
      expect(bob.followers_count).to eq(0)
    end
  end

  describe "Feed functionality" do
    it "shows posts from followed users" do
      alice.follow(bob)
      
      get feed_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bob&#39;s Amazing Clay Bowl")
    end

    it "shows popular posts when not following anyone" do
      get feed_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("popular posts")
    end
  end

  describe "Followers and Following pages" do
    before { alice.follow(bob) }

    it "displays followers list" do
      get followers_user_path(bob)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(alice.display_name)
    end

    it "displays following list" do
      get following_user_path(alice)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(bob.display_name)
    end
  end
end