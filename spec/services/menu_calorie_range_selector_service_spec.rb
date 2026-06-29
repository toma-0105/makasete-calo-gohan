require 'rails_helper'

RSpec.describe MenuCalorieRangeSelectorService do
  subject(:service) { described_class.new(tdee_profile) }

  let(:tdee_profile) { build(:tdee_profile, target_calories: 2000) }
  let(:generator) { instance_double(MenuGeneratorService) }

  before do
    allow(MenuGeneratorService).to receive(:new).and_return(generator)
  end

  def build_menu(total_calories)
    { breakfast: [ instance_double(MealMaster, calories: total_calories) ], lunch: [], dinner: [] }
  end

  describe '#generate' do
    context '1回目の生成で許容範囲（90%〜100%）に収まる場合' do
      let(:in_range_menu) { build_menu(1900) }

      before { allow(generator).to receive(:generate).and_return(in_range_menu) }

      it '再試行せずその献立を返す' do
        expect(service.generate).to eq(in_range_menu)
      end

      it 'MenuGeneratorService#generateが1回だけ呼ばれる' do
        service.generate
        expect(generator).to have_received(:generate).once
      end
    end

    context '範囲外の献立の後に範囲内の献立が生成される場合' do
      let(:under_range_menu) { build_menu(1000) }
      let(:in_range_menu) { build_menu(1950) }

      before do
        allow(generator).to receive(:generate).and_return(under_range_menu, in_range_menu)
      end

      it '範囲内になった時点の献立を返す' do
        expect(service.generate).to eq(in_range_menu)
      end
    end

    context '上限回数（10回）まで範囲内の献立が生成されない場合' do
      let(:far_menu) { build_menu(500) }
      let(:other_menu) { build_menu(1000) }
      let(:closest_menu) { build_menu(1700) }

      before do
        allow(generator).to receive(:generate).and_return(
          far_menu, other_menu, closest_menu, far_menu, other_menu,
          far_menu, other_menu, far_menu, other_menu, far_menu
        )
      end

      it 'エラーにならず、最も目標カロリーに近かった献立を返す' do
        expect(service.generate).to eq(closest_menu)
      end

      it 'MenuGeneratorService#generateが上限回数（10回）呼ばれる' do
        service.generate
        expect(generator).to have_received(:generate).exactly(10).times
      end
    end
  end
end
