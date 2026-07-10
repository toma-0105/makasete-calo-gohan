class AddScalingTypeToMealMasters < ActiveRecord::Migration[7.2]
  # enumの整数値（MealMaster側の定義と一致させる）
  FIXED         = 0
  GRAM_SCALABLE = 1
  UNIT_SCALABLE = 2

  # 移行専用モデル。アプリのMealMasterはこの時点で存在しない列（genre等）のenum定義を
  # 持ちうるため使わない（モデルとテーブルのズレでマイグレーションが壊れるのを防ぐ）
  class MigrationMealMaster < ActiveRecord::Base
    self.table_name = "meal_masters"
  end

  def up
    # 分量の変え方の分類（fixed: 調整不可 / gram_scalable: グラム調整可 / unit_scalable: 個数調整のみ）
    add_column :meal_masters, :scaling_type, :integer, null: false, default: FIXED

    # 既存レコードを料理名のパターンで分類する（シードと同じルール）
    MigrationMealMaster.reset_column_information
    MigrationMealMaster.find_each do |meal_master|
      meal_master.update_column(:scaling_type, scaling_type_for(meal_master.name))
    end
  end

  def down
    remove_column :meal_masters, :scaling_type
  end

  private

  # 個数単位（枚・パック等）を含む → 個数調整のみ / g表記あり → グラム調整可 / どちらもなし → 調整不可
  def scaling_type_for(name)
    if name.match?(/枚|パック|個|本|切れ|尾/)
      UNIT_SCALABLE
    elsif name.match?(/\d+g/)
      GRAM_SCALABLE
    else
      FIXED
    end
  end
end
