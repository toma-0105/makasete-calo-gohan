class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

  # ログイン後はマイページへ（2回目以降のユーザーの最短動線）
  # ※会員登録後の遷移先は Users::RegistrationsController で上書きしている
  def after_sign_in_path_for(resource)
    mypage_path
  end

  private

  # ログイン中ユーザーの「ホーム画面」のパスを返す
  # 会員: マイページ / ゲスト: 最新のTDEE結果（未診断なら診断ページ）
  # ゲストをマイページ以外へ逃がす際の遷移先を一元管理し、リダイレクトループを防ぐ
  def home_path_for(user)
    return mypage_path unless user.guest?

    tdee_profile = user.tdee_profiles.last
    tdee_profile ? tdee_profile_path(tdee_profile) : new_tdee_profile_path
  end
  helper_method :home_path_for

  # アレルギー設定画面から抜けるときの遷移先を返す
  # TDEE未診断（初回オンボーディング中）: TDEE診断へ進める
  # TDEE診断済み（あとから設定変更に来た）: 元のホームへ戻す
  def after_allergen_setup_path_for(user)
    return new_tdee_profile_path if user.tdee_profiles.none?

    home_path_for(user)
  end
  helper_method :after_allergen_setup_path_for


  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end
end
