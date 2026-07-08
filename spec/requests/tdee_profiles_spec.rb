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
    # ログインはどちらの場合にも共通の準備なので、describe直下に置く
    before { sign_in user }

    context "自分の診断結果の場合" do
      let(:tdee_profile) { create(:tdee_profile, user: user, tdee: 2500) }

      before { get tdee_profile_path(tdee_profile) }

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

    context "他人の診断結果の場合" do
      let(:other_user) { create(:user) }
      let(:other_profile) { create(:tdee_profile, user: other_user) }

      it "404 Not Foundを返す" do
        get tdee_profile_path(other_profile)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
