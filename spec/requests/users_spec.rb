require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /users/:id" do
    it "returns http success" do
      get user_path(user)
      expect(response).to have_http_status(:success)
    end

    it "displays user information" do
      get user_path(user)
      expect(response.body).to include(user.username)
      expect(response.body).to include(user.skill_level)
    end
  end

  describe "GET /users/:id/edit" do
    context "when signed in as the user" do
      before { sign_in_as(user) }

      it "returns http success" do
        get edit_user_path(user)
        expect(response).to have_http_status(:success)
      end
    end

    context "when not signed in" do
      it "redirects to sign in page" do
        get edit_user_path(user)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when signed in as different user" do
      before { sign_in_as(other_user) }

      it "redirects to sign in page" do
        get edit_user_path(user)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PUT /users/:id" do
    context "when signed in as the user" do
      before { sign_in_as(user) }

      context "with valid parameters" do
        let(:valid_attributes) do
          {
            username: "newusername",
            bio: "Updated bio",
            skill_level: "advanced"
          }
        end

        it "updates the user" do
          put user_path(user), params: { user: valid_attributes }
          user.reload
          expect(user.username).to eq("newusername")
          expect(user.bio).to eq("Updated bio")
          expect(user.skill_level).to eq("advanced")
        end

        it "redirects to user profile" do
          put user_path(user), params: { user: valid_attributes }
          expect(response).to redirect_to(user_path(user))
        end
      end

      context "with invalid parameters" do
        it "renders edit template" do
          put user_path(user), params: { user: { username: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when not signed in" do
      it "redirects to sign in page" do
        put user_path(user), params: { user: { username: "newname" } }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  private

  def sign_in_as(user)
    post session_path, params: { email: user.email, password: "password123" }
  end
end