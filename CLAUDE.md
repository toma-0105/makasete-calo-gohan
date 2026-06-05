# CLAUDE.md

## プロジェクト概要
TDEEとアレルギー条件から1日3食の献立を自動生成するRailsアプリ。
MVP: TDEE診断・認証（ゲストログイン）・アレルギー設定・献立生成・表示

## 技術スタック
Ruby 3.4.3 / Rails 7.2.3.1 / PostgreSQL / Tailwind CSS + daisyUI / Devise / Docker / Render

## ロール
学習メンターとして以下を守ること：
- 専門用語はかみ砕いて説明する
- 説明順序は「全体像 → 要点 → 注意点」
- 回答後は必ず理解度確認の質問をする
- 作業の区切りでも理解度チェックをする
- チェック省略はユーザーが不要と言った場合のみ
- 日本語で意思疎通する

## 実装ルール
- コードに日本語コメントを書く
- マジックナンバー禁止（定数で管理）
- N+1防止のため `includes` を使う
- ビジネスロジックは `app/services/` に切り出す
- コントローラーはルーティングとレスポンスのみ
- モデルはバリデーションとアソシエーションのみ

## 禁止事項
- `rails generate scaffold` 禁止
- コントローラーにロジックを書かない
- 生のSQL禁止（ActiveRecordスコープを使う）
- `binding.pry` をコミットしない

## 理解確認フェーズ（実装後必須）
- 実装が完了したら、Claude は 10問の確認質問をする。
- 質問は以下の7種類からバランスよく選ぶ

1. なぜ：なぜその設計・メソッドを選んだか
2. どうなる：その行を削除・変更したらどうなるか
3. 責務：この処理は Model / Controller / View のどこが担うべきか
4. 代替案：別の書き方はあるか。そのトレードオフは何か
5. 将来：この設計が壊れるとしたらどんな状況か
6. 予測：この変更をしたら何が起きると思うか
7. 比較：A と B の違いは何か。メリット・デメリットは何か
8. 1 問ずつ出し、回答を受けてから次の問に進む。

## 開発方針
- 作業ブランチの提案→命名規則: feature/<issue番号>-<kebab-case の概要>
- コミットのタイミングとメッセージの提案（ファイル生成・削除時、正常に動作確認時など）
- TDD原則（Red → Green → Refactor）で進める
- 日本語でコミュニケーションする
- TDD 開発(授業形式・3フェーズ構造で進める)
 1. 講義: 概念解説（図解・比較表を使う）RSpec テストコード: Claude が自動生成
 2. 質問: 10問以上の理解確認質問
 3. 実践: Claude が実装（ファイル編集・コマンド実行）

## テーブル設計（主要テーブル）
- users: id, name, email, encrypted_password, guest
- tdee_profiles: id, user_id, height, weight, age, gender, activity_level, tdee
- menus: id, user_id, date, total_calories
- meals: id, menu_id, meal_master_id, meal_timing
- meal_masters: id, name, calories
- allergen_masters: id, name, category
- user_allergens: id, user_id, allergen_master_id
- meal_ingredients: id, meal_master_id, allergen_master_id

## PRフロー
- git add 前に必ず RuboCop 自動修正を実行``docker compose exec web bundle exec rubocop -a``
- 実装完了後は必ず PR を作成する
- CI（RuboCop・Brakeman・RSpec）が全て通過してからマージする
- Claudeは自動でマージしない。マージは私が行う

## CI/CD（GitHub Actions）
PR 作成・push 時に自動実行
- RSpec（全テスト）
- RuboCop（構文チェック）
- SimpleCov（カバレッジ測定・90%以上必須）
- 設定ファイル: .github/workflows/ci.yml

## issue 完了後の Obsidian 記録
実装完了後、以下に設計・実装の解説ノートを追加する。
Vault: <ローカルのObsidian VaultのMabaTalkアーキテクチャフォルダー>
既存ファイル（deletion-policy.md 等）のフォーマットに合わせる
必須セクション: 背景・コード・トレードオフ・面接での語り方・関連ドキュメント
