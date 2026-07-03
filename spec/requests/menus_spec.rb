require 'rails_helper'

RSpec.describe "Menus", type: :request do
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
