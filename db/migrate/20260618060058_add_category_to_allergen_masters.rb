class AddCategoryToAllergenMasters < ActiveRecord::Migration[7.2]
  def change
    add_column :allergen_masters, :category, :integer, null: false, default: 0
  end
end
