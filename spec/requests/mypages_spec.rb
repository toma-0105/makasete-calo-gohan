require 'rails_helper'

RSpec.describe "Mypages", type: :request do
  describe "GET /mypage" do
    context "ログインしている場合" do
      let(:user) { create(:user, name: "テストユーザー", email: "test@example.com") }

      before do
        sign_in user
        get mypage_path
      end

      it "200 OKを返す" do
        expect(response).to have_http_status(:ok)
      end

      it "ログインユーザーの名前が表示される" do
        expect(response.body).to include("テストユーザー")
      end

      it "アレルギー設定変更へのリンクが表示される" do
        expect(response.body).to include(new_user_allergen_path)
      end

      it "献立履歴へのリンクが表示される" do
        expect(response.body).to include("献立履歴を見る")
      end
    end

    context "ゲストとしてログインしている場合" do
      let(:guest) { create(:user, guest: true) }

      before { sign_in guest }

      context "TDEE診断済みの場合" do
        let!(:tdee_profile) { create(:tdee_profile, user: guest) }

        it "TDEE結果ページにリダイレクトされる" do
          get mypage_path
          expect(response).to redirect_to(tdee_profile_path(tdee_profile))
          expect(flash[:alert]).to eq("マイページは会員限定の機能です")
        end
      end

      context "TDEE未診断の場合" do
        it "TDEE診断ページにリダイレクトされる" do
          get mypage_path
          expect(response).to redirect_to(new_tdee_profile_path)
        end
      end
    end

    context "TDEE未診断のユーザーの場合" do
      let(:user) { create(:user) }

      before do
        sign_in user
        get mypage_path
      end

      it "「TDEE診断を始める」ボタンが表示される" do
        expect(response.body).to include("TDEE診断を始める")
        expect(response.body).to include(new_tdee_profile_path)
      end

      it "再診断リンクは表示されない" do
        expect(response.body).not_to include("TDEEを再診断する")
      end
    end

    context "TDEE診断済みのユーザーの場合" do
      let(:user) { create(:user) }

      before do
        create(:tdee_profile, user: user, tdee: 2200)
        # 他人の診断を自分より後に作る（絞り込みが漏れていると、最新の他人の値が表示されてしまう）
        create(:tdee_profile, user: create(:user), tdee: 3333)
        sign_in user
        get mypage_path
      end

      it "自分のTDEEが表示される" do
        expect(response.body).to include("2,200")
      end

      it "他人のTDEEは表示されない" do
        expect(response.body).not_to include("3,333")
      end

      it "「TDEEを再診断する」リンクが表示される" do
        expect(response.body).to include("TDEEを再診断する")
      end

      it "「TDEE診断を始める」ボタンは表示されない" do
        expect(response.body).not_to include("TDEE診断を始める")
      end
    end

    context "TDEE診断のリマインド" do
      let(:user) { create(:user) }
      # 日数はサービスの定数を基準にする
      let(:interval) { TdeeReminderService::REMINDER_INTERVAL_DAYS }

      before { sign_in user }

      context "最後の手動診断から期間が経過している場合" do
        before { create(:tdee_profile, user: user, tdee: 2200, created_at: interval.days.ago) }

        it "再診断を促すモーダルが表示される" do
          get mypage_path
          assert_select "#tdee-reminder-modal", text: /1ヶ月以上/
        end

        it "モーダルに再診断フォームへのリンクがある" do
          get mypage_path
          assert_select "#tdee-reminder-modal a[href=?]", new_tdee_profile_path
        end

        it "閉じた状態をサーバーに持たないため、開くたびに毎回表示される" do
          2.times do
            get mypage_path
            assert_select "#tdee-reminder-modal"
          end
        end
      end

      context "最後の手動診断から期間が経っていない場合" do
        before { create(:tdee_profile, user: user, tdee: 2200, created_at: (interval - 1).days.ago) }

        it "モーダルは表示されない" do
          get mypage_path
          assert_select "#tdee-reminder-modal", count: 0
        end
      end

      context "未診断の場合" do
        it "モーダルは表示されない" do
          get mypage_path
          assert_select "#tdee-reminder-modal", count: 0
        end
      end

      context "古い手動診断のあとに体重記録の自動再計算があった場合" do
        before do
          create(:tdee_profile, user: user, tdee: 2200, created_at: (interval + 1).days.ago)
          create(:tdee_profile, user: user, tdee: 2200, source: :weight_sync, created_at: 1.day.ago)
        end

        it "自動再計算は数えず、モーダルが表示される" do
          get mypage_path
          assert_select "#tdee-reminder-modal"
        end
      end
    end

    context "体重推移グラフ" do
      let(:user) { create(:user) }
      # Chartkickが折れ線グラフを描画するために出力するスクリプトの一部
      let(:line_chart_script) { 'Chartkick["LineChart"]' }

      before { sign_in user }

      context "体重記録がある場合" do
        let(:own_weight) { 65.0 }
        let(:others_weight) { 99.9 }

        before do
          create(:weight_record, user: user, weight: own_weight)
          create(:weight_record, user: create(:user), weight: others_weight)
          get mypage_path
        end

        it "体重推移グラフが表示される" do
          expect(response.body).to include("体重推移")
          expect(response.body).to include(line_chart_script)
        end

        it "TDEE診断履歴カードの下に表示される" do
          expect(response.body.index("TDEE診断履歴")).to be < response.body.index("体重推移")
        end

        it "自分の記録だけがグラフに使われる" do
          expect(response.body).to include(own_weight.to_s)
          expect(response.body).not_to include(others_weight.to_s)
        end
      end

      context "体重記録がない場合" do
        before { get mypage_path }

        it "体重推移グラフは表示されない" do
          expect(response.body).not_to include("体重推移")
          expect(response.body).not_to include(line_chart_script)
        end
      end
    end

    context "ログインしていない場合" do
      before { get mypage_path }

      it "ログインページにリダイレクトされる" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "302 Foundを返す" do
        expect(response).to have_http_status(:found)
      end
    end
  end
end
