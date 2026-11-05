# 既存の献立の中身を、新しく生成した内容に差し替えるサービス
# 献立（Menu）自体は作り直さないため、id・日付・保存済みフラグは変わらない
class MenuRegenerateService
  def initialize(user, menu, tdee_profile)
    @user         = user
    @menu         = menu
    @tdee_profile = tdee_profile
  end

  def regenerate!
    # 献立候補の選定はDB書き込みを伴わないため、ロックやトランザクションの外で行う
    menu_hash = MenuCalorieRangeSelectorService.new(@tdee_profile).generate

    MenuSaveService.new(@user, menu_hash).replace!(@menu)
  end
end
