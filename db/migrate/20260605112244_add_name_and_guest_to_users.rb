class AddNameAndGuestToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name, :string
    add_column :users, :guest, :boolean, default: false, null: false
  end
end
