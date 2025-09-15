require 'rails_helper'

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user, email: "test@example.com") }

  describe "GET /passwords/new" do
    it "returns http success" do
      get new_password_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /passwords" do
    context "with existing user email" do
      it "sends password reset email" do
        expect {
          post passwords_path, params: { email: user.email }
        }.to have_enqueued_mail(PasswordsMailer, :reset)
      end

      it "redirects to sign in page" do
        post passwords_path, params: { email: user.email }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include("Password reset instructions sent")
      end
    end

    context "with non-existing user email" do
      it "still redirects to sign in page" do
        post passwords_path, params: { email: "nonexistent@example.com" }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include("Password reset instructions sent")
      end

      it "does not send email" do
        expect {
          post passwords_path, params: { email: "nonexistent@example.com" }
        }.not_to have_enqueued_mail
      end
    end
  end

  describe "GET /passwords/:token/edit" do
    context "with valid token" do
      it "returns http success" do
        token = user.generate_token_for(:password_reset)
        get edit_password_path(token: token)
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid token" do
      it "redirects to new password page" do
        get edit_password_path(token: "invalid_token")
        expect(response).to redirect_to(new_password_path)
        expect(flash[:alert]).to include("invalid or has expired")
      end
    end
  end

  describe "PUT /passwords/:token" do
    let(:token) { user.generate_token_for(:password_reset) }

    context "with valid password" do
      it "updates the password" do
        put password_path(token: token), params: { 
          password: "newpassword123", 
          password_confirmation: "newpassword123" 
        }
        
        user.reload
        expect(user.authenticate("newpassword123")).to be_truthy
      end

      it "redirects to sign in page" do
        put password_path(token: token), params: { 
          password: "newpassword123", 
          password_confirmation: "newpassword123" 
        }
        
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include("Password has been reset")
      end
    end

    context "with mismatched passwords" do
      it "redirects back to edit page" do
        put password_path(token: token), params: { 
          password: "newpassword123", 
          password_confirmation: "differentpassword" 
        }
        
        expect(response).to redirect_to(edit_password_path(token: token))
        expect(flash[:alert]).to include("did not match")
      end
    end
  end
end