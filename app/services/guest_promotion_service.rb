# ゲストユーザーを正規会員に昇格させるサービス
class GuestPromotionService
  def initialize(user, params)
    @user = user
    @params = params
  end

  def promote
    # 入力された名前・メール・パスワードに加えて guest: false を強制セット
    @user.update(@params.merge(guest: false))
  end
end
