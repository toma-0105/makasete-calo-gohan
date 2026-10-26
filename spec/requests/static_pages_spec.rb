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

    it "便利な機能の説明が表示される" do
      expect(response.body).to include("1品だけ入れ替え")
      expect(response.body).to include("献立をまるごと再生成")
      expect(response.body).to include("日数を選んでまとめて生成")
      expect(response.body).to include("お気に入り料理")
      expect(response.body).to include("体重記録とグラフ")
      expect(response.body).to include("TDEE再診断のお知らせ")
    end

    # 定数を一時的に差し替えて、ページの表示が定数に追従することを確かめる
    # （ビューに数字を直書きしていると、差し替えても表示が変わらずここで落ちる）
    it "日数の上限とお知らせ期間は定数の値を表示する" do
      max_days = 10
      interval_days = 45
      stub_const("MenuPeriodGeneratorService::MAX_GENERATION_DAYS", max_days)
      stub_const("TdeeReminderService::REMINDER_INTERVAL_DAYS", interval_days)

      get how_to_use_path

      expect(response.body).to include("#{MenuPeriodGeneratorService::MIN_GENERATION_DAYS}〜#{max_days}日分")
      expect(response.body).to include("#{interval_days}日以上")
    end

    describe "「会員限定」バッジ" do
      # コントローラーで reject_guest_user している（ゲストが使えない）機能
      let(:member_only_titles) do
        [ "保存して履歴から見返す", "日数を選んでまとめて生成", "お気に入り料理", "体重記録とグラフ", "TDEE再診断のお知らせ" ]
      end

      # ゲストも使える機能（バッジを付けると「使えない」と誤解させてしまう）
      let(:guest_available_titles) do
        [ "TDEE診断", "アレルギー設定", "献立を自動生成", "1品だけ入れ替え", "献立をまるごと再生成" ]
      end

      # タイトルのすぐ後ろ（空白だけを挟んで）に「会員限定」のバッジがあるかを調べる
      def member_only_badge?(title)
        response.body.match?(%r{#{Regexp.escape(title)}\s*<span[^>]*>会員限定</span>})
      end

      it "会員限定の機能には「会員限定」バッジが付く" do
        member_only_titles.each do |title|
          expect(member_only_badge?(title)).to be(true), "「#{title}」に会員限定バッジがありません"
        end
      end

      it "ゲストも使える機能には「会員限定」バッジが付かない" do
        guest_available_titles.each do |title|
          expect(member_only_badge?(title)).to be(false), "「#{title}」に会員限定バッジが付いています"
        end
      end
    end

    it "ゲストログイン・新規登録への導線が表示される" do
      expect(response.body).to include("ゲストでためす")
      expect(response.body).to include(new_user_registration_path)
    end
  end
end
