class AddRecipeFieldsToMealMasters < ActiveRecord::Migration[8.0]
  def change
    add_column :meal_masters, :protein, :decimal
    add_column :meal_masters, :fat, :decimal
    add_column :meal_masters, :carbohydrate, :decimal
    add_column :meal_masters, :ingredients, :jsonb, default: [], null: false
    add_column :meal_masters, :steps, :jsonb, default: [], null: false
  end
end
