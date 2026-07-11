require 'rails_helper'

# seeds.rbのマスタデータ自体の整合性を検査する
# （アレルゲンの紐づけ漏れは除外機能が正常でもアレルギー食材が献立に混入するため）
RSpec.describe 'seedデータの整合性' do
  # 味噌・豆腐などを使う料理を名前から判定するパターン
  SOY_DISH_PATTERN = /味噌|みそ|豆腐|納豆|厚揚げ|油揚げ|豚汁|けんちん/

  before do
    Rails.application.load_seed
  end

  describe 'アレルゲンの紐づけ' do
    it '味噌・豆腐系の料理にはすべて大豆が紐づいている' do
      soy = AllergenMaster.find_by!(name: '大豆')
      soy_dishes = MealMaster.includes(:allergen_masters).select { |meal| meal.name.match?(SOY_DISH_PATTERN) }

      missing = soy_dishes.reject { |meal| meal.allergen_masters.include?(soy) }
      expect(missing.map(&:name)).to be_empty
    end
  end
end
