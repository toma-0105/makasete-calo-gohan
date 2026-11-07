# 期限切れの献立を削除するジョブ（good_job のcronから、定期的に呼ばれる）
class MenuCleanupJob < ApplicationJob
  queue_as :default

  def perform
    MenuRetentionService.new.cleanup!
  end
end
