# Googleログインのコールバックを受け取る（Deviseの基底クラスを継承）
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Googleでの認証後、ここに戻ってくる（アクション名 = プロバイダ名）
  def google_oauth2
    user = OmniauthUserService.new(request.env["omniauth.auth"]).find_or_create

    if user.persisted?
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
      sign_in_and_redirect user, event: :authentication
    else
      redirect_to new_user_session_path, alert: "Googleアカウントでのログインに失敗しました"
    end
  end
end
