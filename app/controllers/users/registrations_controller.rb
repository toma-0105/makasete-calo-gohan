# Deviseの会員登録コントローラーを継承し、登録後の遷移先だけ上書きする
# （after_sign_up_path_for はApplicationControllerではなく
#   RegistrationsController自身で上書きする必要がある）
class Users::RegistrationsController < Devise::RegistrationsController
  protected

  # 会員登録後はまずアレルギー設定へ（献立生成に必要な条件を先に揃えてから TDEE 診断に進ませる）
  def after_sign_up_path_for(resource)
    new_user_allergen_path
  end
end
