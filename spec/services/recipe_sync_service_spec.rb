require 'rails_helper'

RSpec.describe RecipeSyncService do
  describe "#call" do
    # 本番と同じ手順：seedで料理マスタを入れてから、レシピJSONを反映する
    context "seedで料理マスタを入れた後に実行する場合" do
      before { Rails.application.load_seed }

      it "seedで入る料理すべてにPFCが入る（JSONの料理名がseedsと一致している）" do
        described_class.new.call

        expect(MealMaster.where(protein: nil)).to be_empty
      end

      it "seedにない新しい料理が追加される" do
        seeded_count = MealMaster.count
        result = described_class.new.call

        expect(result.imported_count).to be_positive
        expect(MealMaster.count).to eq(seeded_count + result.imported_count)
      end

      it "2回実行しても、料理もアレルゲンの紐づけも増えない" do
        described_class.new.call

        expect { described_class.new.call }.not_to change { [ MealMaster.count, MealIngredient.count ] }
      end

      context "JSONにある料理がDBに見つからない場合" do
        # 親子丼(350g)は最後のバッチの先頭。それ以前の料理を更新した後で失敗させ、巻き戻しを確かめる
        before { MealMaster.find_by!(name: "親子丼(350g)").update!(name: "名前が変わった料理") }

        it "RecordNotFoundが発生し、それまでに更新した料理も元に戻る" do
          expect { described_class.new.call }.to raise_error(ActiveRecord::RecordNotFound)

          expect(MealMaster.where.not(protein: nil)).to be_empty
        end
      end
    end

    context "JSONに検証エラーのあるレシピがある場合" do
      let(:error_issue) { RecipeImportService::Issue.new("不正な料理", :error, "必須項目が不足しています") }
      let(:import_service) { instance_double(RecipeImportService, call: { valid_recipes: [], issues: [ error_issue ] }) }

      before { allow(RecipeImportService).to receive(:new).and_return(import_service) }

      it "InvalidRecipeErrorが発生し、メッセージにレシピ名と理由が入る" do
        expect { described_class.new.call }.to raise_error(RecipeSyncService::InvalidRecipeError, /不正な料理: 必須項目が不足しています/)
      end
    end
  end
end
