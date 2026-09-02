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

    context "ゲストとしてログインしている場合" do
      before { sign_in create(:user, guest: true) }

      it "献立履歴は会員限定のためTDEE診断ページにリダイレクトされる" do
        get menus_path
        expect(response).to redirect_to(new_tdee_profile_path)
        expect(flash[:alert]).to eq("献立履歴は会員限定の機能です")
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

    describe "GET /menus/:id（献立詳細）" do
      context "ログインしている場合" do
        let(:user) { create(:user) }
        let(:menu) { create(:menu, user: user) }

        before { sign_in user }

        it "200 OKを返す" do
          get menu_path(menu)
          expect(response).to have_http_status(:ok)
        end

        context "料理にレシピ情報(材料・手順・PFC)がある場合" do
          let(:allergen) { create(:allergen_master, name: "鶏肉") }
          let(:meal_master) do
            create(:meal_master,
                  name: "鶏むね肉のレモン塩麹グリル(100g)",
                  protein: 24, fat: 4, carbohydrate: 2,
                  ingredients: [ { "name" => "鶏むね肉", "amount" => "100g" } ],
                  steps: [ "鶏むね肉を焼く" ])
          end

          before do
            create(:meal_ingredient, meal_master: meal_master, allergen_master: allergen)
            create(:meal, menu: menu, meal_master: meal_master, meal_timing: :breakfast)
          end

          it "「レシピを見る」トグルが表示される" do
            get menu_path(menu)
            expect(response.body).to include("レシピを見る")
          end

          it "材料が表示される" do
            get menu_path(menu)
            expect(response.body).to include("鶏むね肉")
          end

          it "PFCの内訳が表示される" do
            get menu_path(menu)
            expect(response.body).to include("たんぱく質24g")
          end

          it "アレルギー表示がされる" do
            get menu_path(menu)
            expect(response.body).to include("アレルギー表示")
            expect(response.body).to include("鶏肉")
          end
        end

        context "料理にレシピ情報が無い場合" do
          let(:meal_master) { create(:meal_master) }

          before { create(:meal, menu: menu, meal_master: meal_master, meal_timing: :breakfast) }

          it "「レシピを見る」トグルが表示されない" do
            get menu_path(menu)
            expect(response.body).not_to include("レシピを見る")
          end
        end

        context "アレルゲンはあるがレシピ情報が無い場合（既存データを想定）" do
          let(:allergen) { create(:allergen_master, name: "小麦") }
          let(:meal_master) { create(:meal_master) }

          before do
            create(:meal_ingredient, meal_master: meal_master, allergen_master: allergen)
            create(:meal, menu: menu, meal_master: meal_master, meal_timing: :breakfast)
          end

          it "アレルギー表示はされる" do
            get menu_path(menu)
            expect(response.body).to include("アレルギー表示")
            expect(response.body).to include("小麦")
          end

          it "「レシピを見る」トグルは表示されない" do
            get menu_path(menu)
            expect(response.body).not_to include("レシピを見る")
          end
        end
      end

      context "他人の献立の場合" do
        it "404になる" do
          other_menu = create(:menu)
          sign_in create(:user)
          get menu_path(other_menu)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "ログインしていない場合" do
        it "ログインページにリダイレクトされる" do
          menu = create(:menu)
          get menu_path(menu)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
end
