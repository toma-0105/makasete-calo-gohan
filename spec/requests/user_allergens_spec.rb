require 'rails_helper'

RSpec.describe "UserAllergens", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/user_allergens/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/user_allergens/create"
      expect(response).to have_http_status(:success)
    end
  end
end
