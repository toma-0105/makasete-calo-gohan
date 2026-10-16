# Sentry（エラー監視）の設定
Sentry.init do |config|
  # 送信先。コードに直書きせず、環境変数で管理する
  config.dsn = ENV["SENTRY_DSN"]

  # 本番環境のみ送信する（開発・テストのエラーは送らない）
  config.enabled_environments = %w[production]

  # --- 個人情報を送らない設定 ---
  # 7.1.0の初期値は送らない側だが、8.0で緩む予定のため明示する
  # ログインユーザーの情報（id・メールアドレスなど）
  config.data_collection.user_info = false
  # Cookie（セッション情報）
  config.data_collection.cookies = false
  # URLのクエリ文字列（例: パスワード再設定のトークン、Googleログインの戻りURLに付くコード）
  config.data_collection.url_query_params = false
  # リクエスト・レスポンスのボディ（フォームの入力内容）
  config.data_collection.http_bodies = []
  # ジョブ（good_job）の引数。Deviseのメールジョブにはトークンが含まれる
  config.data_collection.queues = false
end
