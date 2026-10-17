require "rails_helper"

RSpec.describe WeightChartRangeService do
  describe "#call" do
    it "最小値-1kg〜最大値+1kgの範囲を返す" do
      expect(described_class.new([ 60.0, 80.0 ]).call).to eq({ min: 59, max: 81 })
    end

    it "端数は最小値を切り捨て・最大値を切り上げて整数にする" do
      expect(described_class.new([ 62.3, 80.2 ]).call).to eq({ min: 61, max: 82 })
    end

    it "変化が小さい場合でも範囲が広がりすぎない" do
      expect(described_class.new([ 60.0, 60.8 ]).call).to eq({ min: 59, max: 62 })
    end

    it "記録が1件でも範囲が潰れない" do
      expect(described_class.new([ 70.0 ]).call).to eq({ min: 69, max: 71 })
    end

    it "記録のない日（nil）は無視する" do
      expect(described_class.new([ nil, 60.0, nil, 70.0 ]).call).to eq({ min: 59, max: 71 })
    end

    it "記録が1件もない場合は nil を返す" do
      expect(described_class.new([]).call).to be_nil
    end
  end
end
