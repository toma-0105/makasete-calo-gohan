class AddUniqueIndexToMenusOnUserIdAndDate < ActiveRecord::Migration[8.1]
  # 1ユーザー・1日付あたりに残す献立の件数
  MAX_MENUS_PER_DATE = 1

  # マイグレーション専用の簡易モデル
  # アプリ本体のMenu/Mealは今後も変更されるため、過去のマイグレーションが影響を受けないよう独立させる
  class MigrationMenu < ActiveRecord::Base
    self.table_name = "menus"
  end

  class MigrationMeal < ActiveRecord::Base
    self.table_name = "meals"
  end

  def up
    remove_duplicate_menus
    add_index :menus, %i[user_id date], unique: true
  end

  # 削除した重複データは元に戻せないため、戻せるのはインデックスのみ
  def down
    remove_index :menus, %i[user_id date]
  end

  private

  # 同じユーザー・同じ日付の献立が複数ある場合、1件だけ残して他を削除する
  # 残す優先順位: 保存済み → 作成が新しい → idが大きい
  def remove_duplicate_menus
    duplicate_keys = MigrationMenu.group(:user_id, :date).count
                                  .select { |_key, count| count > MAX_MENUS_PER_DATE }
                                  .keys

    duplicate_keys.each do |user_id, date|
      ids = MigrationMenu.where(user_id: user_id, date: date)
                         .order(saved: :desc, created_at: :desc, id: :desc)
                         .pluck(:id)
      # 先頭（残す1件）を除いた残りが削除対象
      _keep_id, *removable_ids = ids
      # meals は menus への外部キーがあるため、先に消す
      MigrationMeal.where(menu_id: removable_ids).delete_all
      MigrationMenu.where(id: removable_ids).delete_all
    end
  end
end
