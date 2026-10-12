class AddSourceToTdeeProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :tdee_profiles, :source, :integer, default: 0, null: false
  end
end
