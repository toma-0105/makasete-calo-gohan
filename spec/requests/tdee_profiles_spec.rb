require 'rails_helper'

RSpec.describe "TdeeProfiles", type: :request do
  let(:user) { create(:user) }

  describe "GET /new" do
    it "returns http success" do
      sign_in user
      get "/tdee_profiles/new"
      expect(response).to have_http_status(:success)
    end
  end
end
