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

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end
end
