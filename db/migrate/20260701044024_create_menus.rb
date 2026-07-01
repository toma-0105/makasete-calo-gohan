class CreateMenus < ActiveRecord::Migration[7.2]
  def change
    create_table :menus do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :total_calories, null: false

      t.timestamps
    end
  end
end
