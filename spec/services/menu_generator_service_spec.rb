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

    context '一品料理が選ばれ、副菜・汁物が追加されない場合' do
      before do
        allow(service).to receive(:select_one_dish?).and_return(true)
        allow(service).to receive(:include_side_dish?).and_return(false)
        allow(service).to receive(:include_soup?).and_return(false)
      end

      it '昼食が一品料理単体になる' do
        result = service.generate
        expect(result[:lunch].size).to eq(1)
        expect(result[:lunch].first.category).to eq('one_dish')
      end

      it '夕食が一品料理単体になる' do
        result = service.generate
        expect(result[:dinner].size).to eq(1)
        expect(result[:dinner].first.category).to eq('one_dish')
      end
    end

    context '一品料理に副菜が追加される場合' do
      before do
        allow(service).to receive(:select_one_dish?).and_return(true)
        allow(service).to receive(:include_side_dish?).and_return(true)
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

    context '一品料理に汁物が追加される場合' do
      before do
        allow(service).to receive(:select_one_dish?).and_return(true)
        allow(service).to receive(:include_side_dish?).and_return(false)
        allow(service).to receive(:include_soup?).and_return(true)
      end

      it '夕食が一品料理+汁物の2品になる（例: 親子丼+味噌汁）' do
        result = service.generate
        expect(result[:dinner].map(&:category)).to contain_exactly('one_dish', 'soup')
      end

      it '昼食はお弁当想定のため汁物は追加されず一品料理単体のままになる' do
        result = service.generate
        expect(result[:lunch].size).to eq(1)
        expect(result[:lunch].first.category).to eq('one_dish')
      end
    end

    context '一品料理に副菜・汁物の両方が追加される場合' do
      before do
        allow(service).to receive(:select_one_dish?).and_return(true)
        allow(service).to receive(:include_side_dish?).and_return(true)
        allow(service).to receive(:include_soup?).and_return(true)
      end

      it '夕食が一品料理+副菜+汁物の3品になる' do
        result = service.generate
        expect(result[:dinner].map(&:category)).to contain_exactly('one_dish', 'side_dish', 'soup')
      end

      it '昼食は汁物を除いた一品料理+副菜の2品になる' do
        result = service.generate
        expect(result[:lunch].map(&:category)).to contain_exactly('one_dish', 'side_dish')
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
  end
end
