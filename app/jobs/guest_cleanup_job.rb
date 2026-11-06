# 期限切れのゲストを削除するジョブ（good_job のcronから、定期的に呼ばれる）
class GuestCleanupJob < ApplicationJob
  queue_as :default

  def perform
    GuestCleanupService.new.cleanup!
  end
end
