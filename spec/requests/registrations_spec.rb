require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  describe "GET /registrations/new" do
    it "returns http success" do
      get new_registration_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /registrations" do
    let(:valid_attributes) do
      {
        email: "newuser@example.com",
        username: "newuser",
        password: "password123",
        password_confirmation: "password123",
        skill_level: "beginner"
      }
    end

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post registrations_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it "redirects to sign in page" do
        post registrations_path, params: { user: valid_attributes }
        expect(response).to redirect_to(new_session_path)
      end

      it "sends email verification" do
        expect {
          post registrations_path, params: { user: valid_attributes }
        }.to have_enqueued_mail(UserMailer, :email_verification)
      end
    end

    context "with invalid parameters" do
      it "does not create a user" do
        expect {
          post registrations_path, params: { user: { email: "invalid" } }
        }.not_to change(User, :count)
      end

      it "renders the new template" do
        post registrations_path, params: { user: { email: "invalid" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end