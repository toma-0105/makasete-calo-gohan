require 'rails_helper'

RSpec.describe "TdeeProfiles", type: :request do
  let(:user) { create(:user) }

  describe "GET /new" do
    it "returns http success" do
      sign_in user
      get "/tdee_profiles/new"
      expect(response).to have_http_status(:success)
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        get new_tdee_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
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

  describe "POST /tdee_profiles（手動のTDEE診断）" do
    let(:params) do
      { tdee_profile: { height: 170, weight: 65, age: 30, gender: "male", activity_level: "lightly_active" } }
    end

    before { sign_in user }

    it "手動診断のプロフィール（diagnosis）が1件増える" do
      expect { post tdee_profiles_path, params: params }
        .to change { user.tdee_profiles.diagnosis.count }.by(1)
    end

    it "体重連動のプロフィール（weight_sync）は増えない" do
      expect { post tdee_profiles_path, params: params }
        .not_to change { user.tdee_profiles.weight_sync.count }
    end

    # source を勝手に書き換えて送られても、手動診断のままになること
    it "paramsにsourceを混ぜても無視される" do
      tampered = { tdee_profile: params[:tdee_profile].merge(source: "weight_sync") }
      post tdee_profiles_path, params: tampered
      expect(user.tdee_profiles.last).to be_diagnosis
    end
  end
end
