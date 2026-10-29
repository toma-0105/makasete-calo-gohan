require 'rails_helper'

RSpec.describe "GuestSessions", type: :request do
  describe "POST /guest_login" do
    it "ゲストユーザーが作成される" do
      expect { post guest_login_path }.to change(User.where(guest: true), :count).by(1)
    end

    it "ログイン状態になり、アレルギー設定画面にリダイレクトされる" do
      post guest_login_path
      expect(response).to redirect_to(new_user_allergen_path)

      # リダイレクト先にアクセスできる＝ログイン済み（未ログインならログイン画面へ飛ばされる）
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it "ゲストログインのフラッシュメッセージが設定される" do
      post guest_login_path
      expect(flash[:notice]).to eq("ゲストとしてログインしました")
    end

    # ログイン中に押されると、会員のセッションが新しいゲストに置き換わったり、
    # ゲストのデータが見えなくなったりするため、ゲストを作らずホームへ戻す（#358）
    context "すでにログインしている場合" do
      context "会員のとき" do
        let(:member) { create(:user) }

        before { sign_in member }

        it "ゲストユーザーを作成せず、マイページにリダイレクトされる" do
          expect { post guest_login_path }.not_to change(User, :count)
          expect(response).to redirect_to(mypage_path)
        end

        it "会員のログイン状態が維持される" do
          post guest_login_path

          # マイページは会員限定のため、ゲストに置き換わっていればリダイレクトされる
          get mypage_path
          expect(response).to have_http_status(:ok)
        end
      end

      context "ゲストのとき" do
        let(:guest) { create(:user, guest: true) }

        before { sign_in guest }

        it "診断前なら、新しいゲストを作成せずTDEE診断ページにリダイレクトされる" do
          expect { post guest_login_path }.not_to change(User, :count)
          expect(response).to redirect_to(new_tdee_profile_path)
        end

        it "診断済みなら、新しいゲストを作成せず診断結果にリダイレクトされる" do
          tdee_profile = create(:tdee_profile, user: guest)

          expect { post guest_login_path }.not_to change(User, :count)
          expect(response).to redirect_to(tdee_profile_path(tdee_profile))
        end
      end
    end
  end
end
