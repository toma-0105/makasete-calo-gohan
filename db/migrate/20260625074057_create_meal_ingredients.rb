class CreateMealIngredients < ActiveRecord::Migration[7.2]
  def change
    create_table :meal_ingredients do |t|
      t.references :meal_master, null: false, foreign_key: true
      t.references :allergen_master, null: false, foreign_key: true

      t.timestamps
    end

    add_index :meal_ingredients, %i[meal_master_id allergen_master_id], unique: true, name: "index_meal_ingredients_on_meal_master_and_allergen"
  end
end
