class AddSavedToMenus < ActiveRecord::Migration[7.2]
  def change
    # 保存済みフラグ（会員が「この献立を保存する」を押したらtrue）
    # 既存レコードは未保存扱いにするため default: false を指定
    add_column :menus, :saved, :boolean, null: false, default: false
  end
end
