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
- 日本語でコミュニケーションする
- RSpecテストは優先度の高いモデルのバリデーションテスト、Factory Botが正しく動くことを確認

## テーブル設計（主要テーブル）
- users: id, name, email, encrypted_password, guest
- tdee_profiles: id, user_id, height, weight, age, gender, activity_level, tdee
- menus: id, user_id, date, total_calories
- meals: id, menu_id, meal_master_id, meal_timing
- meal_masters: id, name, calories, meal_timing, category
- allergen_masters: id, name, category
- user_allergens: id, user_id, allergen_master_id
- meal_ingredients: id, meal_master_id, allergen_master_id

## PRフロー
- git add 前に必ず RuboCop 自動修正を実行``docker compose exec web bundle exec rubocop -a``
- 実装完了後は必ず PR を作成する
- CI（RuboCop・Brakeman・RSpec）が全て通過してからマージする
- Claudeは自動でマージしない。マージは私が行う
