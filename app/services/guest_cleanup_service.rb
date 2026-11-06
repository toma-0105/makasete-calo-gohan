# 作成から一定期間たったゲストユーザーを、関連データごと削除するサービス
class GuestCleanupService
  # ゲストのデータを残しておく日数（作成からこの日数がたったゲストを削除する）
  GUEST_RETENTION_DAYS = 7

  # 期限切れのゲストを削除し、削除した人数を返す
  def cleanup!
    deleted_count = 0

    expired_guests.find_each do |guest|
      # 関連データの削除も含めて1つのトランザクションで行われる。
      # 途中で失敗した場合、そのゲストは丸ごと元に戻る（一部だけ消えた状態にならない）
      guest.destroy!
      deleted_count += 1
    end

    deleted_count
  end

  private

  # 会員ではなくゲストで、作成から保持日数以上たったユーザー
  def expired_guests
    User.where(guest: true, created_at: ..GUEST_RETENTION_DAYS.days.ago)
  end
end
