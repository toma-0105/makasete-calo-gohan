# TDEE診断の見直し時期（リマインドが必要か）を判定する
# 基準は「最後の手動診断」。体重記録による自動再計算（weight_sync）は数えない
class TdeeReminderService
  # 最後の手動診断からこの日数が経過したらリマインドする
  REMINDER_INTERVAL_DAYS = 30

  def initialize(user)
    @user = user
  end

  # リマインドが必要か（未診断のユーザーは対象外）
  def needed?
    return false unless last_diagnosis

    last_diagnosis.created_at <= REMINDER_INTERVAL_DAYS.days.ago
  end

  # 最後の手動診断からの経過日数（切り捨て）。未診断ならnil
  def days_since_diagnosis
    return unless last_diagnosis

    ((Time.current - last_diagnosis.created_at) / 1.day).floor
  end

  private

  # 最後の手動診断（idが大きいほど新しい）
  def last_diagnosis
    @last_diagnosis ||= @user.tdee_profiles.diagnosis.last
  end
end
