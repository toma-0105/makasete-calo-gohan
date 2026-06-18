class CreateUserAllergens < ActiveRecord::Migration[7.2]
  def change
    create_table :user_allergens do |t|
      t.references :user, null: false, foreign_key: true
      t.references :allergen_master, null: false, foreign_key: true

      t.timestamps
    end
  end
end
