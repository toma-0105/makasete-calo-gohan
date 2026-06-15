class AddTargetCaloriesToTdeeProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :tdee_profiles, :target_calories, :decimal
  end
end
