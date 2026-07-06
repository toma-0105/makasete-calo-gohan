require 'rails_helper'

RSpec.describe "Menus", type: :request do
  describe "GET /menus（献立履歴一覧）" do
    context "ログインしている場合" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "200 OKを返す" do
        get menus_path
        expect(response).to have_http_status(:ok)
      end

      it "保存済みの献立の日付と合計カロリーが表示される" do
        create(:menu, :saved, user: user, date: Date.new(2026, 7, 1), total_calories: 1800)
        get menus_path
        expect(response.body).to include("2026年07月01日")
        expect(response.body).to include("1,800")
      end

      it "未保存の献立は表示されない" do
        create(:menu, user: user, date: Date.new(2026, 6, 15))
        get menus_path
        expect(response.body).not_to include("2026年06月15日")
      end

      it "他人の保存済み献立は表示されない" do
        create(:menu, :saved, date: Date.new(2026, 6, 20))
        get menus_path
        expect(response.body).not_to include("2026年06月20日")
      end

      it "新しい日付の献立が先に表示される" do
        create(:menu, :saved, user: user, date: Date.new(2026, 7, 1))
        create(:menu, :saved, user: user, date: Date.new(2026, 7, 2))
        get menus_path
        expect(response.body.index("2026年07月02日")).to be < response.body.index("2026年07月01日")
      end

      it "保存済みの献立がない場合は案内メッセージが表示される" do
        get menus_path
        expect(response.body).to include("保存した献立はまだありません")
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        get menus_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /menus/:id/save" do
    context "会員としてログインしている場合" do
      let(:user)  { create(:user, guest: false) }
      let(:menu)  { create(:menu, user: user) }

      before { sign_in user }

      it "献立が保存済みになる" do
        expect { patch save_menu_path(menu) }
          .to change { menu.reload.saved }.from(false).to(true)
      end

      it "献立表示画面にリダイレクトされる" do
        patch save_menu_path(menu)
        expect(response).to redirect_to(menu_path(menu))
      end

      it "保存成功のフラッシュメッセージが設定される" do
        patch save_menu_path(menu)
        expect(flash[:notice]).to eq("献立を保存しました")
      end

      it "他人の献立は保存できず404になる" do
        other_menu = create(:menu)
        patch save_menu_path(other_menu)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "ゲストとしてログインしている場合" do
      let(:guest) { create(:user, guest: true) }
      let(:menu)  { create(:menu, user: guest) }

      before { sign_in guest }

      it "献立は保存済みにならない" do
        expect { patch save_menu_path(menu) }
          .not_to change { menu.reload.saved }
      end

      it "エラーのフラッシュメッセージが設定される" do
        patch save_menu_path(menu)
        expect(flash[:alert]).to eq("献立の保存は会員登録が必要です")
      end
    end

    context "ログインしていない場合" do
      let(:menu) { create(:menu) }

      it "ログインページにリダイレクトされる" do
        patch save_menu_path(menu)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
