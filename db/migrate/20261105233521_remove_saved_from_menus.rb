class RemoveSavedFromMenus < ActiveRecord::Migration[8.1]
  def change
    # rollback で元に戻せるよう、型とオプションも書いておく
    remove_column :menus, :saved, :boolean, default: false, null: false
  end
end
