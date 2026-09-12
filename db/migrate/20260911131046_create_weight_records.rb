class CreateWeightRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :weight_records do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :weight, null: false
      t.date :recorded_on, null: false

      t.timestamps
    end
    add_index :weight_records, [ :user_id, :recorded_on ], unique: true
  end
end
