class AddCaloriesAndPortionScaleToMeals < ActiveRecord::Migration[7.2]
  # 移行専用モデル。アプリのモデルは将来の定義変更（enum追加等）で
  # この時点のテーブルとズレる可能性があるため使わない
  class MigrationMeal < ActiveRecord::Base
    self.table_name = "meals"
  end

  class MigrationMealMaster < ActiveRecord::Base
    self.table_name = "meal_masters"
  end

  def up
    # 分量倍率（1.0 / 1.25 / 1.5 / 2.0）。既存レコードは等倍扱い
    add_column :meals, :portion_scale, :decimal, precision: 3, scale: 2, null: false, default: 1.0
    # 確定カロリー（マスタの基準カロリー×倍率）。献立生成時点の値を保持する
    add_column :meals, :calories, :decimal

    # 既存レコードには倍率1.0としてマスタのカロリーをそのまま埋める
    # （マスタのカロリーを事前に一括取得し、N+1を避ける）
    MigrationMeal.reset_column_information
    master_calories = MigrationMealMaster.pluck(:id, :calories).to_h
    MigrationMeal.find_each do |meal|
      meal.update_column(:calories, master_calories.fetch(meal.meal_master_id))
    end

    change_column_null :meals, :calories, false
  end

  def down
    remove_column :meals, :calories
    remove_column :meals, :portion_scale
  end
end
