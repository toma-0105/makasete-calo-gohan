# Neon バックアップ・リストア手順書

最終確認日: 2026-10-21 / 関連 Issue: #258

## 1. 現在の構成

| 項目 | 内容 |
|---|---|
| DB | Neon（プロジェクト: makasete-calo-gohan / ブランチ: production） |
| プラン | Free |
| 履歴の保持期間 | 6時間 |
| 復元方式 | Instant restore（PITR: 過去の好きな時点に戻す機能） |
| 手動スナップショット | 1件まで（定期の自動作成は有料プランのみ） |

## 2. 守れる範囲・守れない範囲

- 守れる: 直近6時間以内に起きた事故（誤削除・誤った更新など）
- 守れない: 6時間より前の事故（翌日に気づいた場合など）
- 対策: 危険な作業の前に、手動スナップショットを作る（6章）

## 3. リストア手順（Instant restore）

1. Neon コンソールで production ブランチを選ぶ
2. Postgres database → Backup & Restore → Restore from history を開く
3. Point in time で戻したい時刻を選ぶ（日本時間）
4. 右側の Restore を押すと確認モーダルが開く
5. 内容を確認し、モーダルの Restore を押すと実行される（キャンセルは Cancel）

## 4. 注意点

- Restore ボタンは2回出る。2回目（モーダル内）が実行
- 差分のマージではなく、**全データの上書き**。選んだ時刻より後に登録・保存されたデータは消える
- 実行前の状態は `production_old_<UTC時刻>` という名前のブランチに退避される（退避ブランチを残しておけば取り消せる）
- 時刻の表記が違う。選択欄は日本時間、退避ブランチ名は UTC（9時間差）
- 接続情報（DATABASE_URL）は変わらない（公式ドキュメントの記載）

## 5. 復元後の確認

- 本番アプリでログインできる
- 献立の生成・表示ができる

## 6. 危険な作業の前（スナップショット）

対象: 本番DBに書き込むデプロイ、`recipes:backfill`、マイグレーションを含む更新

1. Backup & Restore の Create snapshot で作成する（Free は1件まで。古いものは削除が必要になる見込み）
2. 作業を行う
3. 問題があればスナップショットの Restore → One-step restore で戻す（公式ドキュメントの記載）

## 7. 確認状況（2026-10-21）

確認済み
- プランと保持期間（Free・6時間）
- Restore ページ・確認モーダルの画面と文言
- SQL Editor の Time Travel で過去時点（当日12:30）を指定して読み取れる

未確認
- 実際のリストア実行と、退避ブランチからの取り消し
- Restore ページの Preview data の動作
- スナップショットの作成・復元
- Time Travel の ON/OFF による件数差の比較

## 8. 参考

- https://neon.com/docs/postgres/backup-restore/branch-restore
- https://neon.com/docs/guides/time-travel-assist
- https://neon.com/docs/guides/backup-restore
