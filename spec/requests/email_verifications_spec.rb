require 'rails_helper'

RSpec.describe "EmailVerifications", type: :request do
  let(:user) { create(:user, email_verified: false) }

  describe "GET /verify_email/:token" do
    context "with valid token" do
      it "verifies the user's email" do
        token = user.generate_token_for(:email_verification)
        get verify_email_path(token: token)
        
        user.reload
        expect(user.email_verified?).to be true
        expect(user.email_verified_at).to be_present
      end

      it "redirects to sign in page" do
        token = user.generate_token_for(:email_verification)
        get verify_email_path(token: token)
        
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "with invalid token" do
      it "redirects to sign in with error" do
        get verify_email_path(token: "invalid_token")
        
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "with already verified email" do
      let(:verified_user) { create(:user, email_verified: true, email_verified_at: Time.current) }

      it "redirects to sign in" do
        token = verified_user.generate_token_for(:email_verification)
        get verify_email_path(token: token)
        
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include("already verified")
      end
    end
  end
end