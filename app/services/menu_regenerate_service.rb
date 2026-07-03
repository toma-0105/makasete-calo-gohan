# 既存の献立を削除して、新しい献立を生成・保存し直すサービス
class MenuRegenerateService
  def initialize(user, old_menu, tdee_profile)
    @user         = user
    @old_menu     = old_menu
    @tdee_profile = tdee_profile
  end

  def regenerate!
    # 献立候補の選定はDB書き込みを伴わないためトランザクションの外で行う
    menu_hash = MenuCalorieRangeSelectorService.new(@tdee_profile).generate

    # 削除と保存を同一トランザクションにまとめ、
    # 保存に失敗した場合は削除もロールバックして献立が消えたままになるのを防ぐ
    ApplicationRecord.transaction do
      @old_menu.destroy!
      MenuSaveService.new(@user, menu_hash).save!
    end
  end
end
