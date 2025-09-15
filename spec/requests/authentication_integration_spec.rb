require 'rails_helper'

RSpec.describe "Authentication Integration", type: :request do
  describe "Complete user registration and authentication flow" do
    let(:user_params) do
      {
        email: "newuser@example.com",
        username: "newuser",
        password: "password123",
        password_confirmation: "password123",
        skill_level: "beginner",
        bio: "I love working with clay!"
      }
    end

    it "allows user to register, verify email, and sign in" do
      # Step 1: User registration
      expect {
        post registrations_path, params: { user: user_params }
      }.to change(User, :count).by(1)
      
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("Account created successfully")
      
      user = User.find_by(email: user_params[:email])
      expect(user).to be_present
      expect(user.email_verified?).to be false

      # Step 2: Email verification
      token = user.generate_token_for(:email_verification)
      get verify_email_path(token: token)
      
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("Email verified successfully")
      
      user.reload
      expect(user.email_verified?).to be true

      # Step 3: User sign in
      post session_path, params: { email: user.email, password: "password123" }
      
      expect(response).to redirect_to(posts_path)
      expect(Session.count).to eq(1)

      # Step 4: Access protected resources
      get edit_user_path(user)
      expect(response).to have_http_status(:success)

      # Step 5: Update profile
      put user_path(user), params: { 
        user: { bio: "Updated bio about my clay work" } 
      }
      
      expect(response).to redirect_to(user_path(user))
      user.reload
      expect(user.bio).to eq("Updated bio about my clay work")

      # Step 6: Sign out
      delete session_path
      expect(response).to redirect_to(new_session_path)
      expect(Session.count).to eq(0)

      # Step 7: Verify access is restricted after sign out
      get edit_user_path(user)
      expect(response).to redirect_to(new_session_path)
    end

    it "handles password reset flow" do
      user = create(:user, email: "test@example.com", password: "oldpassword123", password_confirmation: "oldpassword123")
      
      # Step 1: Request password reset
      post passwords_path, params: { email: user.email }
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("Password reset instructions sent")

      # Step 2: Use password reset token
      token = user.generate_token_for(:password_reset)
      get edit_password_path(token: token)
      expect(response).to have_http_status(:success)

      # Step 3: Update password
      put password_path(token: token), params: {
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
      
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("Password has been reset")

      # Step 4: Sign in with new password
      user.reload
      expect(user.authenticate("newpassword123")).to be_truthy
      expect(user.authenticate("oldpassword123")).to be_falsy

      post session_path, params: { email: user.email, password: "newpassword123" }
      expect(response).to redirect_to(posts_path)
    end
  end
end