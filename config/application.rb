require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1
    config.active_job.queue_adapter = :good_job
    config.good_job.execution_mode = :async
    # 定期実行するジョブ（実際に動かすかどうかは、環境ごとの enable_cron で決める）
    config.good_job.cron = {
      guest_cleanup: {
        cron: "0 * * * *", # 毎時0分
        class: "GuestCleanupJob",
        description: "期限切れのゲストを削除する"
      }
    }

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Minitestの自動生成を無効化
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    config.i18n.default_locale = :ja
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # 日付・時刻の基準を日本時間にする（DBへの保存はUTCのまま。画面や「今日」の判定のときに変換される）
    config.time_zone = "Tokyo"

    # config.eager_load_paths << Rails.root.join("extras")
  end
end
