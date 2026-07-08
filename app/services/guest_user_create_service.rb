# ゲストユーザーを自動生成するサービス
# ランダムなメールアドレス・パスワードで guest: true のユーザーを作成する
class GuestUserCreateService
  GUEST_NAME = "ゲストユーザー"
  # パスワードの長さ（Deviseの最低文字数より十分長いランダム文字列）
  PASSWORD_LENGTH = 16

  def create!
    User.create!(
      name:     GUEST_NAME,
      email:    generate_email,
      password: SecureRandom.urlsafe_base64(PASSWORD_LENGTH),
      guest:    true
    )
  end

  private

  # 衝突しないランダムなメールアドレスを生成する
  def generate_email
    "guest_#{SecureRandom.hex(8)}@example.com"
  end
end
