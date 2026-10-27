require 'rails_helper'

RSpec.describe AllergenMaster, type: :model do
  describe 'DBのNOT NULL制約' do
    it 'nameがNULLだと、バリデーションを通さなくても保存できない' do
      allergen = build(:allergen_master, name: nil)

      # validate: false でモデルのチェックを飛ばし、DBの制約だけを確認する
      expect { allergen.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end
end
