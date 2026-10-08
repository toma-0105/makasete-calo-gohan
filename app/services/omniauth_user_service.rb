# OmniAuth（Googleログイン）の認証結果から、ログインさせるユーザーを返すサービス
# 1) provider + uid で検索 → 2) 同じメールの既存ユーザーに紐付け → 3) 無ければ新規作成

class OmniauthUserService
  # ランダムパスワードの長さ
  PASSWORD_LENGTH = 20

  def initialize(auth)
    @auth = auth
  end

  def find_or_create
    find_by_uid || link_existing_user || create_user
  end

  private

  # 2回目以降のログイン：providerとuid が一致する人を探す
  def find_by_uid
    User.find_by(provider: @auth.provider, uid: @auth.uid)
  end

  # メール登録済みの人がGoogleで入ってきた場合：provider/uid を足すだけ（パスワードは触らない）
  def link_existing_user
    return if email.blank?

    user = User.find_by(email: email)
    return unless user

    user.update!(provider: @auth.provider, uid: @auth.uid)
    user
  end
  # 初めての人：パスワードは本人が知らないランダム値を入れる
  def create_user
    User.create(
      provider: @auth.provider,
      uid:      @auth.uid,
      email:    email,
      name:     @auth.info.name,
      password: Devise.friendly_token(PASSWORD_LENGTH)
    )
  end
  # Devise は保存時にメールを小文字へ揃えるため、検索側も小文字にして合わせる
  def email
    @auth.info.email&.downcase
  end
end
