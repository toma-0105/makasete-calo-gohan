require 'rails_helper'

RSpec.describe MealItemRegenerateService do
  let(:user) { create(:user) }
  let!(:menu) { create(:menu, user: user, total_calories: 1000) }

  # 昼夕共通プールの料理を作り、献立の1品（Meal）として登録する
  def create_menu_meal(name:, category:, calories:, timing: :dinner, genre: :neutral)
    master = create(:meal_master, name: name, meal_timing: :lunch_or_dinner, category: category,
                                  calories: calories, genre: genre)
    create(:meal, menu: menu, meal_master: master, meal_timing: timing, calories: calories)
  end

  # 献立には入っていない、入れ替え候補の料理を作る
  def create_candidate(name:, category:, calories:, genre: :japanese)
    create(:meal_master, name: name, meal_timing: :lunch_or_dinner, category: category,
                         calories: calories, genre: genre)
  end

  # 夕食の3品（主食・主菜・副菜）と、昼食の主菜。主菜・副菜は和食、主食は汎用
  let!(:staple_meal) { create_menu_meal(name: 'ご飯', category: :staple, calories: 250) }
  let!(:main_meal)   { create_menu_meal(name: '焼き鮭', category: :main_dish, calories: 200, genre: :japanese) }
  let!(:side_meal)   { create_menu_meal(name: 'ほうれん草のお浸し', category: :side_dish, calories: 40, genre: :japanese) }
  let!(:lunch_meal)  { create_menu_meal(name: '昼の主菜', category: :main_dish, calories: 300, timing: :lunch, genre: :japanese) }

  describe '.swappable?' do
    # DBに保存せず、カテゴリだけを持つ品を組み立てる
    def meal_of(category)
      build(:meal, meal_master: build(:meal_master, category: category))
    end

    it '主菜・一品料理・副菜は入れ替えできる' do
      results = %i[main_dish one_dish side_dish].map { |category| described_class.swappable?(meal_of(category)) }
      expect(results).to all(be(true))
    end

    it '主食・汁物は入れ替えできない' do
      results = %i[staple soup].map { |category| described_class.swappable?(meal_of(category)) }
      expect(results).to all(be(false))
    end
  end

  describe '#regenerate!' do
    subject(:service) { described_class.new(main_meal) }

    context '同じカテゴリの候補がある場合' do
      let(:new_main_calories) { 180 }
      let!(:new_main_master) { create_candidate(name: '鶏の照り焼き', category: :main_dish, calories: new_main_calories) }

      it '行は削除・再作成されず、同じ行のまま別の主菜に入れ替わる' do
        expect { service.regenerate! }.not_to change(Meal, :count)
        expect(main_meal.reload.meal_master).to eq(new_main_master)
      end

      it '他の品（主食・副菜・昼食）は変わらない' do
        other_meals = [ staple_meal, side_meal, lunch_meal ]
        master_ids_before = other_meals.map(&:meal_master_id)

        service.regenerate!

        expect(other_meals.map { |meal| meal.reload.meal_master_id }).to eq(master_ids_before)
      end

      it '献立の合計カロリーが入れ替え後の合計に更新される' do
        service.regenerate!

        # 主食250 + 新しい主菜180 + 副菜40 + 昼食300
        expect(menu.reload.total_calories).to eq(770)
      end

      context '候補のカロリーが元の品（200kcal）より小さい場合' do
        let(:new_main_calories) { 100 }

        it '倍率をかけて元のカロリーに近づける' do
          service.regenerate!

          main_meal.reload
          expect(main_meal.portion_scale).to eq(2.0)
          expect(main_meal.calories).to eq(200)
        end
      end
    end

    context '副菜を入れ替える場合' do
      subject(:service) { described_class.new(side_meal) }

      let!(:japanese_side) { create_candidate(name: 'ひじきの煮物', category: :side_dish, calories: 100, genre: :japanese) }
      let!(:western_side)  { create_candidate(name: 'コールスロー', category: :side_dish, calories: 100, genre: :western) }

      it '同じ食の主菜とジャンルが合う副菜に入れ替わる' do
        service.regenerate!
        expect(side_meal.reload.meal_master).to eq(japanese_side)
      end

      it '分量は変えず、等倍のままにする' do
        service.regenerate!

        side_meal.reload
        expect(side_meal.portion_scale).to eq(1.0)
        expect(side_meal.calories).to eq(100)
      end
    end

    context '主菜を入れ替えるとき、同じ食の他の品がジャンルを持っている場合' do
      let!(:staple_meal) { create_menu_meal(name: '食パン', category: :staple, calories: 250, genre: :western) }
      let!(:side_meal)   { create_menu_meal(name: 'サラダ', category: :side_dish, calories: 40) }
      let!(:western_main)  { create_candidate(name: 'チキンソテー', category: :main_dish, calories: 200, genre: :western) }
      let!(:japanese_main) { create_candidate(name: '鯖の味噌煮', category: :main_dish, calories: 200, genre: :japanese) }

      it '他の品に合うジャンルの主菜に入れ替わる' do
        service.regenerate!
        expect(main_meal.reload.meal_master).to eq(western_main)
      end
    end

    context '入れ替えられる候補が無い場合' do
      it '使用済みの料理しか残っていなければ、NoCandidateErrorになる' do
        # 昼夕プールの主菜は「今の主菜」と「昼食で使用中の主菜」だけ
        expect { service.regenerate! }.to raise_error(described_class::NoCandidateError)
      end

      it 'アレルゲンを含む料理しか残っていなければ、NoCandidateErrorになる' do
        allergen = create(:allergen_master, name: '鶏肉')
        create(:user_allergen, user: user, allergen_master: allergen)
        allergen_main = create_candidate(name: '鶏の唐揚げ', category: :main_dish, calories: 200)
        create(:meal_ingredient, meal_master: allergen_main, allergen_master: allergen)

        expect { service.regenerate! }.to raise_error(described_class::NoCandidateError)
      end

      it '失敗しても、品も合計カロリーも変わらない' do
        original_master_id = main_meal.meal_master_id
        original_total = menu.total_calories

        expect { service.regenerate! }.to raise_error(described_class::NoCandidateError)

        expect(main_meal.reload.meal_master_id).to eq(original_master_id)
        expect(menu.reload.total_calories).to eq(original_total)
      end
    end

    context '使用済みの料理やアレルゲンを含む料理が候補に混ざっている場合' do
      it 'それらを避けて、残った候補に入れ替わる' do
        allergen = create(:allergen_master, name: '鶏肉')
        create(:user_allergen, user: user, allergen_master: allergen)
        allergen_main = create_candidate(name: '鶏の唐揚げ', category: :main_dish, calories: 200)
        create(:meal_ingredient, meal_master: allergen_main, allergen_master: allergen)
        safe_main = create_candidate(name: '鯖の味噌煮', category: :main_dish, calories: 200)

        service.regenerate!

        expect(main_meal.reload.meal_master).to eq(safe_main)
      end
    end

    context '主食・汁物を入れ替えようとした場合' do
      it '主食はNotSwappableErrorになり、品は変わらない' do
        create_candidate(name: 'うどん', category: :staple, calories: 250)
        original_master_id = staple_meal.meal_master_id

        expect { described_class.new(staple_meal).regenerate! }.to raise_error(described_class::NotSwappableError)
        expect(staple_meal.reload.meal_master_id).to eq(original_master_id)
      end

      it '汁物はNotSwappableErrorになり、品は変わらない' do
        soup_meal = create_menu_meal(name: '味噌汁', category: :soup, calories: 50)
        create_candidate(name: '豚汁', category: :soup, calories: 120)
        original_master_id = soup_meal.meal_master_id

        expect { described_class.new(soup_meal).regenerate! }.to raise_error(described_class::NotSwappableError)
        expect(soup_meal.reload.meal_master_id).to eq(original_master_id)
      end
    end

    context '合計カロリーの更新に失敗した場合' do
      let!(:new_main_master) { create_candidate(name: '鶏の照り焼き', category: :main_dish, calories: 180) }

      before do
        allow(menu).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it '品の入れ替えも取り消され、元のまま残る（ロールバック）' do
        original_master_id = main_meal.meal_master_id

        expect { service.regenerate! }.to raise_error(ActiveRecord::RecordInvalid)

        expect(main_meal.reload.meal_master_id).to eq(original_master_id)
      end
    end
  end
end
