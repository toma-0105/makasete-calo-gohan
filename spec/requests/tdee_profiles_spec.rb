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

  describe "GET /tdee_profiles/:id（診断結果画面）" do
    let(:tdee_profile) { create(:tdee_profile, user: user, tdee: 2500) }

    before do
      sign_in user
      get tdee_profile_path(tdee_profile)
    end

    it "200 OKを返す" do
      expect(response).to have_http_status(:ok)
    end

    it "計算されたTDEEが表示される" do
      expect(response.body).to include("2,500")
    end

    it "献立を生成するボタンが表示される" do
      expect(response.body).to include("献立を生成する")
      expect(response.body).to include(menus_path)
    end
  end
end
