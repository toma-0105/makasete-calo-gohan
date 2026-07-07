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
end
