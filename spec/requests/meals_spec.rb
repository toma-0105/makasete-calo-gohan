require "rails_helper"

RSpec.describe "Meals", type: :request do
  # 1品（meal）単位の入れ替え（#327）
  describe "POST /menus/:menu_id/meals/:id/regenerate" do
    let(:user)            { create(:user) }
    let(:menu)            { create(:menu, user: user, total_calories: 1000) }
    let(:old_main_master) { create(:meal_master, name: "焼き鮭", meal_timing: :lunch_or_dinner, category: :main_dish, calories: 200) }
    let(:staple_master)   { create(:meal_master, name: "ご飯", meal_timing: :lunch_or_dinner, category: :staple, calories: 252) }
    let!(:main_meal)      { create(:meal, menu: menu, meal_master: old_main_master, meal_timing: :dinner, calories: 200) }
    let!(:staple_meal)    { create(:meal, menu: menu, meal_master: staple_master, meal_timing: :dinner, calories: 252) }

    context "会員としてログインしている場合" do
      before { sign_in user }

      context "入れ替えの候補がある場合" do
        let!(:new_main_master) do
          create(:meal_master, name: "鶏の照り焼き", meal_timing: :lunch_or_dinner, category: :main_dish, calories: 180)
        end

        it "その1品だけが別の主菜に入れ替わり、献立の画面に戻る" do
          post regenerate_menu_meal_path(menu, main_meal)

          expect(response).to redirect_to(menu_path(menu))
          expect(main_meal.reload.meal_master).to eq(new_main_master)
          expect(staple_meal.reload.meal_master).to eq(staple_master)
        end

        it "献立の合計カロリーが更新される" do
          post regenerate_menu_meal_path(menu, main_meal)

          # 主食252 + 新しい主菜180
          expect(menu.reload.total_calories).to eq(432)
        end
      end

      context "入れ替えの候補が無い場合" do
        it "「他の候補がありません」と通知し、品は変わらない" do
          post regenerate_menu_meal_path(menu, main_meal)

          expect(response).to redirect_to(menu_path(menu))
          expect(flash[:alert]).to eq("他の候補がありません")
          expect(main_meal.reload.meal_master).to eq(old_main_master)
        end
      end

      context "主食を入れ替えようとした場合（画面にはマークが出ないが、直接リクエストされたとき）" do
        before { create(:meal_master, name: "うどん", meal_timing: :lunch_or_dinner, category: :staple) }

        it "入れ替えできない旨を通知し、品は変わらない" do
          post regenerate_menu_meal_path(menu, staple_meal)

          expect(response).to redirect_to(menu_path(menu))
          expect(flash[:alert]).to eq("この品は入れ替えできません")
          expect(staple_meal.reload.meal_master).to eq(staple_master)
        end
      end

      context "他人の献立の品の場合" do
        let(:other_meal) { create(:meal) }

        it "他人の献立のURLでは404になる" do
          post regenerate_menu_meal_path(other_meal.menu, other_meal)
          expect(response).to have_http_status(:not_found)
        end

        it "自分の献立のURLに他人の品のIDを指定しても404になる" do
          post regenerate_menu_meal_path(menu, other_meal)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "ゲストとしてログインしている場合" do
      let(:user) { create(:user, guest: true) }
      let!(:new_main_master) do
        create(:meal_master, name: "鶏の照り焼き", meal_timing: :lunch_or_dinner, category: :main_dish, calories: 180)
      end

      before { sign_in user }

      it "会員と同じように入れ替えできる" do
        post regenerate_menu_meal_path(menu, main_meal)

        expect(response).to redirect_to(menu_path(menu))
        expect(main_meal.reload.meal_master).to eq(new_main_master)
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        post regenerate_menu_meal_path(menu, main_meal)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
