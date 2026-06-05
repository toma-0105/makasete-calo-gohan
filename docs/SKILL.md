# SKILL.md - makasete-calo-gohan

## 1. プロジェクト概要
- **アプリ名**: まかせてカロごはん（makasete-calo-gohan）
- **コンセプト**: TDEE・アレルギー・食材条件をもとに献立を生成し、「何を食べるか考えるストレス」をゼロにするサービス
- **ターゲット**: カロリーを意識したいが、毎日の献立を考えることに負担を感じている人

---

## 2. 技術スタック

### 言語・フレームワーク
- Ruby 3.4.3
- Rails 7.2.3

### 認証
- Devise 4.9.4（導入済み）
- ゲストログイン機能あり

### データベース
- PostgreSQL（pg gem使用）

### フロントエンド
- Tailwind CSS + daisyUI
- JavaScript（Hotwire: Turbo / Stimulus）
- jsbundling-rails / cssbundling-rails
- simple_calendar（献立カレンダー表示）※本リリース実装予定

### インフラ・環境
- Docker（開発・本番環境統一）
- Render+Neon（本番デプロイ先）
- Node.js 20.x / Yarn 1.22.22

### メール
- Resend（認証メール送信）

### バックグラウンド処理
- ActiveJob（MVP）
- Sidekiq（本リリースで検討）
- whenever（cron定期実行）

### テスト
- RSpec / FactoryBot / Faker / Capybara / Selenium WebDriver

### その他
- Active Storage（レシピ・食材写真）
- Brakeman（セキュリティ）
- RuboCop Rails Omakase（コード品質）

---

## 4. MVPで作る機能（優先順）

1. **消費カロリー算出（TDEE診断）** - 身体情報・活動レベルから1日の消費カロリーを計算
2. **ユーザー認証・ゲストログイン** - Devise + ゲストログイン実装
3. **食物アレルギー設定**（任意・選択式）
4. **献立自動生成** - 目標カロリー × 時間帯（朝・昼・晩）で1日3食を選出
5. **献立閲覧** - 当日・翌日の献立と合計カロリーを表示

---

## 5. 開発ルール

### 命名規則
- モデル名：英語・単数形（例: `User`, `Menu`, `Allergy`）
- コントローラ：複数形（例: `UsersController`, `MenusController`）
- テーブル名：複数形（Railsデフォルト）

### コーディング規則
- RuboCop Rails Omakase に準拠
- サービスクラスは `app/services/` に配置
- 複雑なロジックはモデルに書かず、サービスクラスに切り出す

---


## 8. テーブル設計（schema.rb）
### users（ユーザー）
| カラム名 | 型 | 内容 |
|---|---|---|
| id | bigint | 主キー（自動採番） |
| name | string | ユーザー名 |
| email | string | メールアドレス（ユニーク制約） |
| encrypted_password | string | 暗号化パスワード（Devise管理） |
| guest | boolean | ゲストユーザーフラグ |
| created_at | datetime | 作成日時（自動） |
| updated_at | datetime | 更新日時（自動） |
 
### tdee_profiles（TDEE情報）
| カラム名 | 型 | 内容 |
|---|---|---|
| id | bigint | 主キー（自動採番） |
| user_id | bigint | 外部キー（users.id） |
| height | decimal | 身長（cm） |
| weight | decimal | 体重（kg） |
| age | integer | 年齢 |
| gender | integer | 性別（enum） |
| activity_level | integer | 活動レベル（enum） |
| tdee | decimal | 1日の消費カロリー（kcal） |
| created_at | datetime | 作成日時（自動） |
| updated_at | datetime | 更新日時（自動） |
 
### menus（1日の献立）
| カラム名 | 型 | 内容 |
|---|---|---|
| id | bigint | 主キー（自動採番） |
| user_id | bigint | 外部キー（users.id） |
| date | date | 献立の対象日 |
| total_calories | decimal | 3食の合計カロリー（kcal） |
| created_at | datetime | 作成日時（自動） |
| updated_at | datetime | 更新日時（自動） |
 
### meals（各食事）
| カラム名 | 型 | 内容 |
|---|---|---|
| id | bigint | 主キー（自動採番） |
| menu_id | bigint | 外部キー（menus.id） |
| meal_master_id | bigint | 外部キー（meal_masters.id） |
| meal_timing | integer | 食事タイプ（朝食／昼食／夕食） |
| created_at | datetime | 作成日時（自動） |
| updated_at | datetime | 更新日時（自動） |
 
### meal_masters（料理マスタ）
| カラム名 | 型 | 内容 |
|---|---|---|
| id | bigint | 主キー（自動採番） |
| name | string | 料理名（例：納豆ご飯） |
| calories | decimal | カロリー（kcal） |
| created_at | datetime | 作成日時（自動） |
| updated_at | datetime | 更新日時（自動） |
 
### allergen_masters（アレルギーマスタ）
| カラム名 | 型 | 内容 |
|---|---|---|
| id | bigint | 主キー（自動採番） |
| name | string | アレルギー名（例：卵・小麦・えび） |
| category | string | 区分（特定原材料／特定原材料に準ずるもの） |
| created_at | datetime | 作成日時（自動） |
| updated_at | datetime | 更新日時（自動） |
 
### user_allergens（ユーザーとアレルギーの中間テーブル）
| カラム名 | 型 | 内容 |
|---|---|---|
| id | bigint | 主キー（自動採番） |
| user_id | bigint | 外部キー（users.id） |
| allergen_master_id | bigint | 外部キー（allergen_masters.id） |
| created_at | datetime | 作成日時（自動） |
| updated_at | datetime | 更新日時（自動） |
 
### meal_ingredients（料理とアレルギーの中間テーブル）
| カラム名 | 型 | 内容 |
|---|---|---|
| id | bigint | 主キー（自動採番） |
| meal_master_id | bigint | 外部キー（meal_masters.id） |
| allergen_master_id | bigint | 外部キー（allergen_masters.id） |
| created_at | datetime | 作成日時（自動） |
| updated_at | datetime | 更新日時（自動） |
 
---
 
### テーブルのリレーション
| # | リレーション | 種類 | 説明 |
|---|---|---|---|
| 1 | users → tdee_profiles | 1対1 | 1人のユーザーに1つのTDEE情報 |
| 2 | users → menus | 1対多 | 1人のユーザーが複数の献立を持つ |
| 3 | users → user_allergens | 1対多 | 1人のユーザーが複数のアレルギーを登録する |
| 4 | menus → meals | 1対多 | 1つの献立が朝・昼・夜の3食を持つ |
| 5 | meal_masters → meals | 1対多 | 1つの料理マスタが複数の食事記録で使われる |
| 6 | allergen_masters → user_allergens | 1対多 | 1つのアレルギーマスタが複数のユーザーに登録される |
| 7 | meal_masters → meal_ingredients | 1対多 | 1つの料理マスタが複数のアレルギーと紐づく |
| 8 | allergen_masters → meal_ingredients | 1対多 | 1つのアレルギーマスタが複数の料理と紐づく |
 
※ Deviseのデフォルト構成。今後MVPの機能実装に合わせてカラムを追加予定。

---

### 今後追加予定のテーブル（MVP）

### テスト規則
- 機能実装後にRSpecでテストを書く
- FactoryBotでテストデータを管理
- 統合テストはCapybaraを使用

---

## 6. ユーザー登録フロー（UX設計）

```
① TDEE診断（約30秒）
   ↓
② ユーザー登録 or ゲスト利用を選択（約30〜60秒）
   ↓
③ アレルギー設定（任意・約30秒）
   ↓
④「献立を生成」ボタン → 即座に1日3食を表示
```

合計所要時間: 約90〜120秒

---

## 7. 画面・設計資料

- 画面遷移図: Figma（MVP）
- ER図: draw.io（MVP）