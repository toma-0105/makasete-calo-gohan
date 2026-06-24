class CreateMealMasters < ActiveRecord::Migration[7.2]
  def change
    create_table :meal_masters do |t|
      t.string :name, null: false
      t.integer :calories, null: false
      t.integer :meal_timing, null: false
      t.integer :category, null: false

      t.timestamps
    end
  end
end
