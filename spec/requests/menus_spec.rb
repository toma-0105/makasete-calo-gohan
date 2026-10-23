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

  describe "GET /menus/period（期間一覧）" do
    let(:user) { create(:user) }

    before { sign_in user }

    context "献立がある場合" do
      let(:menu) { create(:menu, user: user, date: Date.new(2026, 7, 1)) }

      before do
        rice = create(:meal_master, name: "ご飯(150g)", category: :staple)
        salmon = create(:meal_master, name: "焼き鮭1切れ(80g)", category: :main_dish)
        create(:meal, menu: menu, meal_master: rice, meal_timing: :breakfast, calories: 234)
        create(:meal, menu: menu, meal_master: salmon, meal_timing: :dinner, calories: 137)
      end

      it "日付と合計カロリーが表示される" do
        get period_menus_path(menu_ids: menu.id)
        expect(response.body).to include("2026年07月01日")
        expect(response.body).to include("2,000")
      end

      it "アコーディオンの中に食事ごとの料理名とカロリーが表示される" do
        get period_menus_path(menu_ids: menu.id)
        expect(response.body).to include("朝食", "夕食", "ご飯(150g)", "焼き鮭1切れ(80g)", "234", "137")
      end

      it "詳細・保存ページへのリンクが表示される" do
        get period_menus_path(menu_ids: menu.id)
        expect(response.body).to include(%(href="#{menu_path(menu)}"))
      end

      it "会員には「マイページに戻る」が表示され、マイページへ遷移する" do
        get period_menus_path(menu_ids: menu.id)
        expect(Capybara.string(response.body)).to have_link("マイページに戻る", href: mypage_path)
      end
    end

    context "ゲストとしてログインしている場合" do
      # 外側の before { sign_in user } がゲストでログインするように、user を上書きする
      let(:user) { create(:user, guest: true) }
      let!(:tdee_profile) { create(:tdee_profile, user: user) }
      let(:menu) { create(:menu, user: user) }

      before { create(:meal, menu: menu) }

      it "会員限定のマイページではなく、TDEE診断結果へ戻るリンクが表示される" do
        get period_menus_path(menu_ids: menu.id)
        page = Capybara.string(response.body)
        expect(page).to have_link("診断結果に戻る", href: tdee_profile_path(tdee_profile))
        expect(page).not_to have_link("マイページに戻る")
      end
    end

    it "複数日分でもN+1が発生しない（発生するとBulletが例外を出してテストが失敗する）" do
      menus = create_list(:menu, 3, user: user)
      menus.each { |menu| create(:meal, menu: menu) }

      get period_menus_path(menu_ids: menus.map(&:id).join(","))
      expect(response).to have_http_status(:ok)
    end

    it "他人の献立は表示されず、見つからないメッセージが出る" do
      other_menu = create(:menu, date: Date.new(2026, 6, 20))

      get period_menus_path(menu_ids: other_menu.id)
      expect(response.body).not_to include("2026年06月20日")
      expect(response.body).to include("献立が見つかりませんでした")
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

      it "同じ日付の保存済み献立がある場合は置き換えの通知が出る" do
        create(:menu, :saved, user: user, date: menu.date)
        patch save_menu_path(menu)
        expect(flash[:notice]).to eq("献立を保存しました。同じ日付の保存済み献立を置き換えました")
      end

      it "同じ日付の保存済み献立がない場合は置き換えの通知は出ない" do
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

        it "戻るリンクが表示され、保険の戻り先は会員のホーム（マイページ）になる" do
          get menu_path(menu)
          expect(Capybara.string(response.body))
            .to have_css("a[data-controller='back-link'][href='#{mypage_path}']")
        end

        it "献立の再生成フォームは、遷移時に履歴を置き換える設定になっている" do
          get menu_path(menu)
          expect(Capybara.string(response.body))
            .to have_css("form[action='#{regenerate_menu_path(menu)}'][data-turbo-action='replace']")
        end

        context "献立に主食・主菜・副菜・汁物・一品料理がある場合（#327）" do
          # 表示順が登録順に依存しないよう、表示したい順とは逆の順で登録する
          def add_meal(category, name, timing: :dinner)
            master = create(:meal_master, name: name, meal_timing: :lunch_or_dinner, category: category)
            create(:meal, menu: menu, meal_master: master, meal_timing: timing)
          end

          let!(:soup_meal)     { add_meal(:soup, "テスト汁物") }
          let!(:side_meal)     { add_meal(:side_dish, "テスト副菜") }
          let!(:main_meal)     { add_meal(:main_dish, "テスト主菜") }
          let!(:staple_meal)   { add_meal(:staple, "テスト主食") }
          let!(:one_dish_meal) { add_meal(:one_dish, "テスト一品料理", timing: :lunch) }

          it "同じ食事の中は 主食 → 主菜 → 副菜 → 汁物 の順に並ぶ" do
            get menu_path(menu)

            names = response.body.scan(/テスト(?:主食|主菜|副菜|汁物)/).uniq
            expect(names).to eq(%w[テスト主食 テスト主菜 テスト副菜 テスト汁物])
          end

          it "主菜・副菜・一品料理の行には入れ替えフォームがあり、履歴を置き換える設定になっている" do
            get menu_path(menu)

            html = Capybara.string(response.body)
            [ main_meal, side_meal, one_dish_meal ].each do |meal|
              expect(html)
                .to have_css("form[action='#{regenerate_menu_meal_path(menu, meal)}'][data-turbo-action='replace']")
            end
          end

          it "主食・汁物の行には入れ替えフォームがない" do
            get menu_path(menu)

            html = Capybara.string(response.body)
            [ staple_meal, soup_meal ].each do |meal|
              expect(html).not_to have_css("form[action='#{regenerate_menu_meal_path(menu, meal)}']")
            end
          end
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

      context "ゲストとしてログインしている場合" do
        let(:guest) { create(:user, guest: true) }
        let!(:tdee_profile) { create(:tdee_profile, user: guest) }
        let(:menu) { create(:menu, user: guest) }

        before { sign_in guest }

        it "戻るリンクの保険の戻り先は、会員限定のマイページではなくTDEE診断結果になる" do
          get menu_path(menu)
          expect(Capybara.string(response.body))
            .to have_css("a[data-controller='back-link'][href='#{tdee_profile_path(tdee_profile)}']")
        end

        it "入れ替えマークは表示され、お気に入り（★）は表示されない（#327）" do
          master = create(:meal_master, meal_timing: :lunch_or_dinner, category: :main_dish)
          meal = create(:meal, menu: menu, meal_master: master, meal_timing: :dinner)

          get menu_path(menu)

          html = Capybara.string(response.body)
          expect(html).to have_css("form[action='#{regenerate_menu_meal_path(menu, meal)}']")
          expect(html).not_to have_css("form[action='#{meal_master_favorite_path(master)}']")
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
  describe "POST /menus/:id/regenerate" do
    context "会員としてログインしている場合" do
      let(:user)       { create(:user) }
      let(:other_menu) { create(:menu) }

      before { sign_in user }

      it "他人の献立は再生成できず404になる" do
        post regenerate_menu_path(other_menu)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
