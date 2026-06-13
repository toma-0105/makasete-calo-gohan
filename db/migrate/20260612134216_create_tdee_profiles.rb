class CreateTdeeProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :tdee_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :height
      t.decimal :weight
      t.integer :age
      t.integer :gender
      t.integer :activity_level
      t.decimal :tdee

      t.timestamps
    end
  end
end
