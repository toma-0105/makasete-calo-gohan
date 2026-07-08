require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  describe "GET /（トップページ）" do
    it "200 OKを返す" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "使い方ページへのリンクが表示される" do
      get root_path
      expect(response.body).to include(how_to_use_path)
    end
  end

  describe "GET /how_to_use（使い方ページ）" do
    before { get how_to_use_path }

    it "ログインなしでも200 OKを返す" do
      expect(response).to have_http_status(:ok)
    end

    it "ステップごとの説明が表示される" do
      expect(response.body).to include("TDEE診断")
      expect(response.body).to include("アレルギー設定")
      expect(response.body).to include("献立を自動生成")
    end

    it "ゲストログイン・新規登録への導線が表示される" do
      expect(response.body).to include("ゲストでためす")
      expect(response.body).to include(new_user_registration_path)
    end
  end
end
