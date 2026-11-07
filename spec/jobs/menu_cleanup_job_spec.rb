require 'rails_helper'

RSpec.describe MenuCleanupJob, type: :job do
  describe '#perform' do
    it 'MenuRetentionService を呼んで、期限切れの献立を削除する' do
      service = instance_double(MenuRetentionService, cleanup!: 0)
      allow(MenuRetentionService).to receive(:new).and_return(service)

      described_class.perform_now

      expect(service).to have_received(:cleanup!)
    end
  end

  # cronの定義が間違っていると、本番でジョブが一度も動かないため、設定の中身を確かめる
  describe 'good_job のcron設定' do
    let(:entry) { Rails.application.config.good_job.cron[:menu_cleanup] }

    it '登録されたクラスが実在し、ジョブとして動かせる' do
      expect(entry[:class].constantize).to be < ApplicationJob
    end

    it 'cronの書き方が正しい（解釈できる）' do
      expect(Fugit::Cron.parse(entry[:cron])).not_to be_nil
    end
  end
end
