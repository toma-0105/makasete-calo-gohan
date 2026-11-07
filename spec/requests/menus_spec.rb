require 'rails_helper'

RSpec.describe "Menus", type: :request do
  describe "GET /menus（直近の献立）" do
    # 日本時間 2026-11-07 12:00 に固定する（昨日は 11/6、おとといは 11/5）
    # 「昨日以降だけを表示する」仕様のため、日付が動くとテストが成り立たなくなる
    let(:now) { Time.utc(2026, 11, 7, 3, 0) }

    around { |example| travel_to(now) { example.run } }

    context "ログインしている場合" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "200 OKを返す" do
        get menus_path
        expect(response).to have_http_status(:ok)
      end

      it "献立の日付と合計カロリーが表示される" do
        create(:menu, user: user, date: Date.new(2026, 11, 8), total_calories: 1800)
        get menus_path
        expect(response.body).to include("2026年11月08日")
        expect(response.body).to include("1,800")
      end

      it "他人の献立は表示されない" do
        create(:menu, date: Date.new(2026, 11, 9))
        get menus_path
        expect(response.body).not_to include("2026年11月09日")
      end

      it "昨日以降の献立が表示され、昨日より前の献立は表示されない" do
        create(:menu, user: user, date: Date.new(2026, 11, 5))
        create(:menu, user: user, date: Date.new(2026, 11, 6))
        create(:menu, user: user, date: Date.new(2026, 11, 7))
        create(:menu, user: user, date: Date.new(2026, 11, 10))
        get menus_path
        expect(response.body).not_to include("2026年11月05日")
        expect(response.body).to include("2026年11月06日", "2026年11月07日", "2026年11月10日")
      end

      it "古い日付の献立が先に表示される（今日が上のほうに来る）" do
        create(:menu, user: user, date: Date.new(2026, 11, 7))
        create(:menu, user: user, date: Date.new(2026, 11, 8))
        create(:menu, user: user, date: Date.new(2026, 11, 13))
        get menus_path
        expect(response.body.index("2026年11月07日")).to be < response.body.index("2026年11月08日")
        expect(response.body.index("2026年11月08日")).to be < response.body.index("2026年11月13日")
      end

      it "表示できる献立がない場合は案内メッセージが表示される" do
        # 昨日より前の献立しかない場合も、案内メッセージになる
        create(:menu, user: user, date: Date.new(2026, 11, 5))
        get menus_path
        expect(response.body).to include("直近の献立はまだありません")
      end
    end

    context "ゲストとしてログインしている場合" do
      before { sign_in create(:user, guest: true) }

      it "直近の献立は会員限定のためTDEE診断ページにリダイレクトされる" do
        get menus_path
        expect(response).to redirect_to(new_tdee_profile_path)
        expect(flash[:alert]).to eq("直近の献立は会員限定の機能です")
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

      it "詳細ページへのリンクが表示される" do
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
      # 同じユーザーは同じ日付の献立を持てないため、日付を1日ずつずらして作る
      menus = Array.new(3) { |i| create(:menu, user: user, date: Date.new(2026, 7, 1) + i.days) }
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

    describe "GET /menus/:id（献立詳細）" do
      context "ログインしている場合" do
        let(:user) { create(:user) }
        let(:menu) { create(:menu, user: user) }

        before { sign_in user }

        it "200 OKを返す" do
          get menu_path(menu)
          expect(response).to have_http_status(:ok)
        end

        it "保存ボタンは表示されない（生成した時点で自動的に保存されるため）" do
          get menu_path(menu)
          expect(response.body).not_to include("この献立を保存する")
          expect(response.body).not_to include("保存済みの献立です")
        end

        it "今日の献立の見出しは「今日の献立」になる" do
          get menu_path(menu)
          expect(Capybara.string(response.body)).to have_css("h1", text: "今日の献立")
        end

        it "今日以外の献立の見出しは日付つきになる" do
          tomorrow = Date.current + 1.day
          other_day_menu = create(:menu, user: user, date: tomorrow)

          get menu_path(other_day_menu)
          page = Capybara.string(response.body)
          expect(page).to have_css("h1", text: "#{tomorrow.month}月#{tomorrow.day}日の献立")
          expect(page).not_to have_css("h1", text: "今日の献立")
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

    # 再生成後に、同じ献立のまま中身だけが新しい料理に差し替わること
    context "自分の献立を再生成する場合" do
      let(:user)         { create(:user) }
      let(:menu)         { create(:menu, user: user) }
      let(:old_master)   { create(:meal_master, name: "再生成前の料理") }
      let(:new_master)   { create(:meal_master, name: "再生成後の料理") }
      let(:menu_hash) do
        { breakfast: [ MenuGeneratorService::SelectedMeal.new(new_master, 1.0) ], lunch: [], dinner: [] }
      end

      before do
        create(:tdee_profile, user: user)
        create(:meal, menu: menu, meal_master: old_master)
        # 献立候補の選定ロジックはサービスのspecで担保するため、固定の結果を返すようにスタブする
        selector = instance_double(MenuCalorieRangeSelectorService, generate: menu_hash)
        allow(MenuCalorieRangeSelectorService).to receive(:new).and_return(selector)
        sign_in user
        post regenerate_menu_path(menu)
      end

      it "献立は作り直されず、同じ献立のまま残る" do
        expect(Menu.exists?(menu.id)).to be true
        expect(user.menus.count).to eq(1)
      end

      it "同じ献立の画面にリダイレクトされる" do
        expect(response).to redirect_to(menu_path(menu))
      end

      it "新しい料理が表示され、古い料理は表示されない" do
        follow_redirect!
        expect(response.body).to include(new_master.name)
        expect(response.body).not_to include(old_master.name)
      end
    end
  end

  describe "POST /menus（献立生成）" do
    let(:user) { create(:user) }

    before { sign_in user }

    context "TDEE診断済みの場合" do
      let(:master) { create(:meal_master, name: "生成された料理", calories: 300) }
      let(:menu_hash) do
        { breakfast: [ MenuGeneratorService::SelectedMeal.new(master, 1.0) ], lunch: [], dinner: [] }
      end

      before do
        create(:tdee_profile, user: user)
        # 献立候補の選定ロジックはサービスのspecで担保するため、固定の結果を返すようにスタブする
        selector = instance_double(MenuCalorieRangeSelectorService, generate: menu_hash)
        allow(MenuCalorieRangeSelectorService).to receive(:new).and_return(selector)
      end

      it "自分の献立として保存される" do
        expect { post menus_path }.to change { user.menus.count }.by(1)
      end

      it "生成した献立が結果一覧に反映される" do
        post menus_path
        follow_redirect!
        expect(response.body).to include(master.name)
      end

      context "今日の献立がすでにある場合（1日分）" do
        let!(:existing_menu) { create(:menu, user: user, date: Date.current) }

        before { create(:meal, menu: existing_menu) }

        it "献立は作られない" do
          expect { post menus_path }.not_to change(Menu, :count)
        end

        it "既存の献立の一覧へ遷移し、すでにある旨が通知される" do
          post menus_path
          expect(response).to redirect_to(period_menus_path(menu_ids: existing_menu.id))
          expect(flash[:alert]).to eq("#{Date.current.strftime('%-m月%-d日')}の献立はすでにあります")
        end
      end

      context "3日分を生成して、今日の献立だけがすでにある場合" do
        let!(:existing_menu) { create(:menu, user: user, date: Date.current) }

        before { create(:meal, menu: existing_menu) }

        it "足りない2日分だけ作られる" do
          expect { post menus_path, params: { days: 3 } }.to change { user.menus.count }.by(2)
        end

        it "既存の献立も含めた3日分の一覧へ遷移し、スキップした旨が通知される" do
          post menus_path, params: { days: 3 }
          expect(response).to redirect_to(period_menus_path(menu_ids: user.menus.order(:date).ids.join(",")))
          expect(flash[:notice]).to eq("#{Date.current.strftime('%-m月%-d日')}の献立はすでにあるため、スキップして残りの日を生成しました")
        end

        it "一覧に3日分の献立が表示される" do
          post menus_path, params: { days: 3 }
          follow_redirect!
          expect(response.body).to include("3日分の献立")
        end
      end
    end

    context "TDEE未診断の場合" do
      it "献立は作られず、TDEE診断画面へリダイレクトされる" do
        expect { post menus_path }.not_to change(Menu, :count)
        expect(response).to redirect_to(new_tdee_profile_path)
      end
    end
  end
end
