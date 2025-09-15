require 'rails_helper'

RSpec.describe "Appeals", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/appeals/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/appeals/show"
      expect(response).to have_http_status(:success)
    end
  end

end
