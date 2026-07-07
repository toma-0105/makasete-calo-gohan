class AddCaloriesAndPortionScaleToMeals < ActiveRecord::Migration[7.2]
  def up
    # 分量倍率（1.0 / 1.25 / 1.5 / 2.0）。既存レコードは等倍扱い
    add_column :meals, :portion_scale, :decimal, precision: 3, scale: 2, null: false, default: 1.0
    # 確定カロリー（マスタの基準カロリー×倍率）。献立生成時点の値を保持する
    add_column :meals, :calories, :decimal

    # 既存レコードには倍率1.0としてマスタのカロリーをそのまま埋める
    Meal.reset_column_information
    Meal.includes(:meal_master).find_each do |meal|
      meal.update_column(:calories, meal.meal_master.calories)
    end

    change_column_null :meals, :calories, false
  end

  def down
    remove_column :meals, :calories
    remove_column :meals, :portion_scale
  end
end
