class CreateAllergenMasters < ActiveRecord::Migration[7.2]
  def change
    create_table :allergen_masters do |t|
      t.string :name

      t.timestamps
    end
  end
end
