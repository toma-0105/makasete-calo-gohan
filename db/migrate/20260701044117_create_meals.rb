class CreateMeals < ActiveRecord::Migration[7.2]
  def change
    create_table :meals do |t|
      t.references :menu, null: false, foreign_key: true
      t.references :meal_master, null: false, foreign_key: true
      t.integer :meal_timing, null: false

      t.timestamps
    end
  end
end
