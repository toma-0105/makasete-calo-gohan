# 献立を「昨日以降だけ残す」ためのルールと、期限切れの献立の削除を担当するサービス
# 画面に出す範囲と削除する範囲が食い違わないよう、「昨日」の計算をここに集めている
class MenuRetentionService
  # 何日前の献立まで残すか（1 = 昨日まで）
  # 夜遅くに0時をまたいでも、見ていた献立がすぐ消えないようにする猶予
  RETENTION_DAYS = 1

  # 残す最も古い日付（日本時間の今日から、猶予の日数をさかのぼった日）
  def self.oldest_kept_date
    Date.current - RETENTION_DAYS.days
  end

  # 画面に表示する献立（残す期間内のもの）
  def self.recent_menus(user)
    user.menus.where(date: oldest_kept_date..)
  end

  # 期限切れの献立を、料理（meals）ごと削除して、削除した件数を返す
  def cleanup!
    deleted_count = 0

    expired_menus.find_each do |menu|
      # 献立と料理の削除は1つのトランザクションで行われる。
      # 途中で失敗した場合、その献立は丸ごと元に戻る
      menu.destroy!
      deleted_count += 1
    end

    deleted_count
  end

  private

  # 残す期間より前の日付の献立（全ユーザー分）
  def expired_menus
    Menu.includes(:meals).where(date: ...self.class.oldest_kept_date)
  end
end
