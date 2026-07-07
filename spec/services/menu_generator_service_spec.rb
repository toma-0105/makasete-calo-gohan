require 'rails_helper'

RSpec.describe MenuGeneratorService do
  subject(:service) { described_class.new }

  before do
    # 朝食用データ
    create(:meal_master, meal_timing: :breakfast, category: :staple)
    create(:meal_master, meal_timing: :breakfast, category: :main_dish)
    create(:meal_master, meal_timing: :breakfast, category: :side_dish)
    create(:meal_master, meal_timing: :breakfast, category: :soup)

    # 昼食・夕食共通プール用データ（昼夜で重複しないことを確認するため複数件用意）
    create_list(:meal_master, 2, meal_timing: :lunch_or_dinner, category: :staple)
    create_list(:meal_master, 2, meal_timing: :lunch_or_dinner, category: :main_dish)
    create_list(:meal_master, 2, meal_timing: :lunch_or_dinner, category: :side_dish)
    create_list(:meal_master, 2, meal_timing: :lunch_or_dinner, category: :soup)
    # 昼・夜それぞれが一品料理を選べるよう2件用意する
    create_list(:meal_master, 2, meal_timing: :lunch_or_dinner, category: :one_dish)
  end

  describe '#generate' do
    context '一品料理・汁物のいずれも選ばれない場合（基本形）' do
      before do
        allow(service).to receive(:select_one_dish?).and_return(false)
        allow(service).to receive(:include_soup?).and_return(false)
      end

      it '朝食が主食・主菜・副菜の3品になる' do
        result = service.generate
        expect(result[:breakfast].map(&:category)).to contain_exactly('staple', 'main_dish', 'side_dish')
      end

      it '昼食が主食・主菜・副菜の3品になる' do
        result = service.generate
        expect(result[:lunch].map(&:category)).to contain_exactly('staple', 'main_dish', 'side_dish')
      end

      it '夕食が主食・主菜・副菜の3品になる' do
        result = service.generate
        expect(result[:dinner].map(&:category)).to contain_exactly('staple', 'main_dish', 'side_dish')
      end

      it '昼食と夕食で同じ料理が重複しない' do
        result = service.generate
        lunch_ids = result[:lunch].map(&:id)
        dinner_ids = result[:dinner].map(&:id)
        expect(lunch_ids & dinner_ids).to be_empty
      end
    end

    context '汁物が選ばれる場合' do
      before do
        allow(service).to receive(:select_one_dish?).and_return(false)
        allow(service).to receive(:include_soup?).and_return(true)
      end

      it '朝食に汁物が追加され4品になる' do
        result = service.generate
        expect(result[:breakfast].map(&:category)).to contain_exactly('staple', 'main_dish', 'side_dish', 'soup')
      end

      it '夕食に汁物が追加され4品になる' do
        result = service.generate
        expect(result[:dinner].map(&:category)).to contain_exactly('staple', 'main_dish', 'side_dish', 'soup')
      end

      it '昼食はお弁当想定のため汁物は追加されず3品のままになる' do
        result = service.generate
        expect(result[:lunch].map(&:category)).to contain_exactly('staple', 'main_dish', 'side_dish')
      end
    end

    context '一品料理が選ばれ、汁物が追加されない場合' do
      before do
        allow(service).to receive(:select_one_dish?).and_return(true)
        allow(service).to receive(:include_soup?).and_return(false)
      end

      it '昼食が一品料理+副菜の2品になる（例: カレーライス+サラダ）' do
        result = service.generate
        expect(result[:lunch].map(&:category)).to contain_exactly('one_dish', 'side_dish')
      end

      it '夕食が一品料理+副菜の2品になる' do
        result = service.generate
        expect(result[:dinner].map(&:category)).to contain_exactly('one_dish', 'side_dish')
      end
    end

    context '一品料理が選ばれ、汁物が追加される場合' do
      before do
        allow(service).to receive(:select_one_dish?).and_return(true)
        allow(service).to receive(:include_soup?).and_return(true)
      end

      it '夕食が一品料理+副菜+汁物の3品になる（例: 親子丼+サラダ+味噌汁）' do
        result = service.generate
        expect(result[:dinner].map(&:category)).to contain_exactly('one_dish', 'side_dish', 'soup')
      end

      it '昼食はお弁当想定のため汁物は追加されず一品料理+副菜の2品になる' do
        result = service.generate
        expect(result[:lunch].map(&:category)).to contain_exactly('one_dish', 'side_dish')
      end
    end

    context '目標カロリーが指定されている場合（#103 カロリー配分方式）' do
      subject(:service) { described_class.new(target_calories: target_calories) }

      before do
        allow(service).to receive(:select_one_dish?).and_return(false)
        allow(service).to receive(:include_soup?).and_return(false)

        # 分量調整の選択肢となるカロリー違いの主食・主菜を用意する
        [ 100, 150, 200, 250, 300, 350 ].each do |cal|
          create(:meal_master, meal_timing: :breakfast, category: :staple, calories: cal)
          create(:meal_master, meal_timing: :breakfast, category: :main_dish, calories: cal)
          create(:meal_master, meal_timing: :lunch_or_dinner, category: :main_dish, calories: cal)
        end
        [ 100, 150, 200, 250, 300, 350, 400, 450 ].each do |cal|
          create(:meal_master, meal_timing: :lunch_or_dinner, category: :staple, calories: cal)
        end
      end

      context '目標2,000kcalの場合' do
        let(:target_calories) { 2000 }

        it '1日の合計カロリーが目標の±10%に収まる' do
          total = service.generate.values.flatten.sum(&:calories)
          expect(total).to be_within(200).of(2000)
        end

        it '副菜の倍率は等倍のまま' do
          side_dishes = service.generate.values.flatten.select { |meal| meal.category == 'side_dish' }
          expect(side_dishes.map(&:portion_scale)).to all(eq(1.0))
        end
      end

      context '目標3,200kcalの場合（基準カロリーの組み合わせだけでは届かない）' do
        let(:target_calories) { 3200 }

        it '主食・主菜に等倍より大きい分量倍率が適用される' do
          scaled_meals = service.generate.values.flatten.select { |meal| meal.portion_scale > 1.0 }
          expect(scaled_meals).not_to be_empty
        end

        it '1日の合計カロリーが目標の±10%に収まる' do
          total = service.generate.values.flatten.sum(&:calories)
          expect(total).to be_within(320).of(3200)
        end
      end
    end

    context '目標カロリーが未指定の場合' do
      before do
        allow(service).to receive(:select_one_dish?).and_return(false)
        allow(service).to receive(:include_soup?).and_return(false)
      end

      it '全ての料理の分量倍率が等倍になる' do
        result = service.generate
        expect(result.values.flatten.map(&:portion_scale)).to all(eq(1.0))
      end
    end

    context 'スープ系の一品料理（うどん）がある場合' do
      before do
        create(:meal_master, meal_timing: :lunch_or_dinner, category: :one_dish, name: '天ぷらうどん')
        allow(service).to receive(:select_one_dish?).and_return(true)
      end

      it '昼食の一品料理候補から「うどん」を含む料理が除外される' do
        result = service.generate
        expect(result[:lunch].first.name).not_to include('うどん')
      end
    end

    context '除外IDが指定されている場合（#26 アレルギー除外）' do
      subject(:service) { described_class.new(excluded_meal_master_ids: [ excluded_breakfast_staple.id, excluded_lunch_or_dinner_staple.id ]) }

      let!(:excluded_breakfast_staple) { create(:meal_master, meal_timing: :breakfast, category: :staple) }
      let!(:excluded_lunch_or_dinner_staple) { create(:meal_master, meal_timing: :lunch_or_dinner, category: :staple) }

      before do
        allow(service).to receive(:select_one_dish?).and_return(false)
        allow(service).to receive(:include_soup?).and_return(false)
      end

      it '除外IDの料理が朝食に選ばれない' do
        result = service.generate
        expect(result[:breakfast].map(&:id)).not_to include(excluded_breakfast_staple.id)
      end

      it '除外IDの料理が昼食・夕食に選ばれない' do
        result = service.generate
        selected_ids = (result[:lunch] + result[:dinner]).map(&:id)
        expect(selected_ids).not_to include(excluded_lunch_or_dinner_staple.id)
      end
    end
  end

  describe 'ジャンル制約（#105）' do
    before do
      # 和・洋それぞれの主菜と、和・洋・汎用の主食・副菜・汁物を用意する
      { japanese: 2, western: 2 }.each do |genre, count|
        create_list(:meal_master, count, meal_timing: :breakfast, category: :main_dish, genre: genre)
        create_list(:meal_master, count, meal_timing: :breakfast, category: :staple, genre: genre)
        create_list(:meal_master, count, meal_timing: :breakfast, category: :side_dish, genre: genre)
        create_list(:meal_master, count, meal_timing: :breakfast, category: :soup, genre: genre)
        create_list(:meal_master, count + 1, meal_timing: :lunch_or_dinner, category: :main_dish, genre: genre)
        create_list(:meal_master, count + 1, meal_timing: :lunch_or_dinner, category: :staple, genre: genre)
        create_list(:meal_master, count + 1, meal_timing: :lunch_or_dinner, category: :side_dish, genre: genre)
        create_list(:meal_master, count + 1, meal_timing: :lunch_or_dinner, category: :soup, genre: genre)
      end
    end

    it '主菜がジャンルを持つ食事では、他の料理が同ジャンルか汎用のみになる' do
      10.times do
        service = described_class.new
        allow(service).to receive(:select_one_dish?).and_return(false)

        service.generate.each_value do |meals|
          lead = meals.find { |meal| meal.category == 'main_dish' }
          # 主菜が汎用の場合は絞り込まない設計のため検証対象外
          next if lead.meal_master.neutral?

          other_genres = meals.map { |meal| meal.meal_master.genre }
          expect(other_genres).to all(be_in([ lead.meal_master.genre, 'neutral' ]))
        end
      end
    end

    describe '#genre_matched（絞り込みのフォールバック）' do
      it '主役のジャンルに合う候補が無い場合は、絞り込みを諦めて全候補を返す' do
        japanese_staple = create(:meal_master, category: :staple, genre: :japanese)
        chinese_main = create(:meal_master, category: :main_dish, genre: :chinese)

        scope = MealMaster.where(id: japanese_staple.id)
        result = described_class.new.send(:genre_matched, scope, chinese_main)
        expect(result).to include(japanese_staple)
      end

      it '主役が汎用（neutral）の場合は絞り込まない' do
        neutral_main = create(:meal_master, category: :main_dish, genre: :neutral)
        result = described_class.new.send(:genre_matched, MealMaster.staple, neutral_main)
        expect(result).to eq(MealMaster.staple)
      end
    end
  end

  describe '品数バランス（#106）' do
    it 'どの食事も最低2品以上で構成される' do
      10.times do
        result = described_class.new.generate
        result.each_value do |meals|
          expect(meals.size).to be >= 2
        end
      end
    end
  end

  describe '分量調整方式（scaling_type）ごとの倍率制限' do
    before do
      # 個数調整のみ・調整不可の料理もプールに混ぜて、制限が守られることを確認する
      create(:meal_master, meal_timing: :breakfast, category: :staple, calories: 150, scaling_type: :unit_scalable)
      create(:meal_master, meal_timing: :breakfast, category: :main_dish, calories: 100, scaling_type: :unit_scalable)
      create_list(:meal_master, 2, meal_timing: :lunch_or_dinner, category: :staple, calories: 200, scaling_type: :unit_scalable)
      create_list(:meal_master, 2, meal_timing: :lunch_or_dinner, category: :main_dish, calories: 150, scaling_type: :fixed)
    end

    it '適用される倍率は料理ごとに許可された候補に必ず収まる' do
      selected_meals = 10.times.flat_map do
        described_class.new(target_calories: 2400).generate.values.flatten
      end

      selected_meals.each do |meal|
        allowed_scales = described_class::PORTION_SCALES_BY_TYPE.fetch(meal.meal_master.scaling_type)
        expect(allowed_scales).to include(meal.portion_scale)
      end
    end
  end
end
