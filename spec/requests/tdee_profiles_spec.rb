require 'rails_helper'

RSpec.describe "TdeeProfiles", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/tdee_profiles/new"
      expect(response).to have_http_status(:success)
    end
  end
end
