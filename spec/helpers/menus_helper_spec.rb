require 'rails_helper'

RSpec.describe MenusHelper, type: :helper do
  describe '#meal_display_name' do
    it 'グラム調整の料理は名前中のグラム数を倍率で換算して表示する' do
      master = build(:meal_master, name: 'ご飯(150g)', scaling_type: :gram_scalable)
      meal = build(:meal, meal_master: master, portion_scale: 1.5)
      expect(helper.meal_display_name(meal)).to eq('ご飯(225g)')
    end

    it '等倍の場合は名前をそのまま表示する' do
      master = build(:meal_master, name: 'ご飯(150g)', scaling_type: :gram_scalable)
      meal = build(:meal, meal_master: master, portion_scale: 1.0)
      expect(helper.meal_display_name(meal)).to eq('ご飯(150g)')
    end

    it '個数調整の料理は倍率がかかっても名前を変えない' do
      master = build(:meal_master, name: '納豆1パック(45g)', scaling_type: :unit_scalable)
      meal = build(:meal, meal_master: master, portion_scale: 2.0)
      expect(helper.meal_display_name(meal)).to eq('納豆1パック(45g)')
    end
  end

  describe '#meal_scale_label' do
    it '個数調整の料理が2倍のとき「×2」を返す' do
      master = build(:meal_master, name: '納豆1パック(45g)', scaling_type: :unit_scalable)
      meal = build(:meal, meal_master: master, portion_scale: 2.0)
      expect(helper.meal_scale_label(meal)).to eq('×2')
    end

    it 'グラム調整の料理にはラベルを付けない（グラム表示で伝わるため）' do
      master = build(:meal_master, name: 'ご飯(150g)', scaling_type: :gram_scalable)
      meal = build(:meal, meal_master: master, portion_scale: 1.5)
      expect(helper.meal_scale_label(meal)).to be_nil
    end

    it '等倍のときはラベルを付けない' do
      master = build(:meal_master, name: '納豆1パック(45g)', scaling_type: :unit_scalable)
      meal = build(:meal, meal_master: master, portion_scale: 1.0)
      expect(helper.meal_scale_label(meal)).to be_nil
    end
  end

  describe '#meals_grouped_by_timing' do
    let(:menu) { create(:menu) }

    # 指定した食事タイミング・カテゴリの料理を献立に追加する
    def add_meal(timing, category, name)
      master = create(:meal_master, name: name, category: category)
      create(:meal, menu: menu, meal_master: master, meal_timing: timing)
    end

    # コントローラーと同じく、meals・meal_masterを先読みした献立を返す
    # （先読みしないとBulletがN+1を検知してテストが失敗する）
    def preloaded_menu
      Menu.includes(meals: :meal_master).find(menu.id)
    end

    it '朝食・昼食・夕食の順にラベル付きで返す' do
      add_meal(:dinner, :main_dish, '夕の主菜')
      add_meal(:breakfast, :main_dish, '朝の主菜')
      add_meal(:lunch, :main_dish, '昼の主菜')

      labels = helper.meals_grouped_by_timing(preloaded_menu).map(&:first)
      expect(labels).to eq(%w[朝食 昼食 夕食])
    end

    it '同じ食事の中ではカテゴリの表示順（主食→主菜→副菜→汁物）に並べる' do
      add_meal(:breakfast, :soup, '汁物')
      add_meal(:breakfast, :side_dish, '副菜')
      add_meal(:breakfast, :main_dish, '主菜')
      add_meal(:breakfast, :staple, '主食')

      _label, meals = helper.meals_grouped_by_timing(preloaded_menu).first
      expect(meals.map { |meal| meal.meal_master.name }).to eq(%w[主食 主菜 副菜 汁物])
    end

    it '一品料理は副菜・汁物より前に並ぶ（enumの定義順では末尾になるため）' do
      add_meal(:lunch, :soup, '汁物')
      add_meal(:lunch, :side_dish, '副菜')
      add_meal(:lunch, :one_dish, '一品料理')

      _label, meals = helper.meals_grouped_by_timing(preloaded_menu).first
      expect(meals.map { |meal| meal.meal_master.name }).to eq(%w[一品料理 副菜 汁物])
    end

    it '料理がない食事は含めない' do
      add_meal(:lunch, :main_dish, '昼の主菜')

      labels = helper.meals_grouped_by_timing(preloaded_menu).map(&:first)
      expect(labels).to eq(%w[昼食])
    end
  end
end
