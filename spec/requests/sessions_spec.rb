require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, email: "test@example.com", password: "password123") }

  describe "GET /session/new" do
    it "returns http success" do
      get new_session_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      it "signs in the user" do
        post session_path, params: { email: user.email, password: "password123" }
        expect(response).to redirect_to(posts_path)
      end

      it "creates a session" do
        expect {
          post session_path, params: { email: user.email, password: "password123" }
        }.to change(Session, :count).by(1)
      end
    end

    context "with invalid credentials" do
      it "redirects back to sign in" do
        post session_path, params: { email: user.email, password: "wrongpassword" }
        expect(response).to redirect_to(new_session_path)
      end

      it "does not create a session" do
        expect {
          post session_path, params: { email: user.email, password: "wrongpassword" }
        }.not_to change(Session, :count)
      end
    end
  end

  describe "DELETE /session" do
    before do
      post session_path, params: { email: user.email, password: "password123" }
    end

    it "signs out the user" do
      delete session_path
      expect(response).to redirect_to(new_session_path)
    end

    it "destroys the session" do
      expect {
        delete session_path
      }.to change(Session, :count).by(-1)
    end
  end
end