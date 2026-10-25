require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#page_container_classes' do
    it '幅の種類を省略すると content（読み物・一覧用）の幅クラスを返す' do
      expect(helper.page_container_classes).to eq(described_class::PAGE_WIDTH_CLASSES[:content])
    end

    it 'スマホ幅は全ての種類で max-w-sm に固定される（PC向けの広がりは md: 以降だけ）' do
      described_class::PAGE_WIDTH_CLASSES.each_key do |width|
        expect(helper.page_container_classes(width).split).to include('max-w-sm')
      end
    end

    it 'wide だけ lg 以上でさらに広がる（献立詳細の3列用）' do
      expect(helper.page_container_classes(:wide)).to include('lg:max-w-6xl')
      expect(helper.page_container_classes(:form)).not_to include('lg:')
    end

    it '画面固有のクラスを extra で追加できる' do
      expect(helper.page_container_classes(:form, 'px-5 py-6').split).to include('px-5', 'py-6')
    end

    it '未定義の種類を渡すとKeyErrorになる（打ち間違いに気づける）' do
      expect { helper.page_container_classes(:unknown) }.to raise_error(KeyError)
    end
  end
end
