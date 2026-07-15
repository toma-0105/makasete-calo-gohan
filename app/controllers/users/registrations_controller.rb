# Deviseの会員登録コントローラーを継承し、登録後の遷移先だけ上書きする
# （after_sign_up_path_for はApplicationControllerではなく
#   RegistrationsController自身で上書きする必要がある）
class Users::RegistrationsController < Devise::RegistrationsController
  protected

  # 会員登録後はそのままTDEE診断へ（新規ユーザーは必ず未診断のため、迷わせず診断に直行させる）
  def after_sign_up_path_for(resource)
    new_user_allergen_path
  end
end
