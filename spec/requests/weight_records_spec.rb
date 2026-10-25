require "rails_helper"

RSpec.describe "WeightRecords", type: :request do
  let(:user) { create(:user) }
  # コントローラーの定数を参照し、上限を変えてもテストが追従するようにする
  let(:limit) { WeightRecordsController::RECENT_RECORDS_LIMIT }

  before { sign_in user }

  # 今日から days_ago_range 日前の範囲で、1日1件ずつ体重記録を作る
  def create_records(days_ago_range)
    days_ago_range.each do |days_ago|
      create(:weight_record, user: user, recorded_on: Date.current - days_ago)
    end
  end

  # 一覧に表示される日付の形式（YYYY/MM/DD）に変換する
  def list_label(date)
    date.strftime("%Y/%m/%d")
  end

  # 今日から count 日分を、新しい順に並べた期待値にする
  def expected_labels(count)
    (0...count).map { |days_ago| list_label(Date.current - days_ago) }
  end

  # レスポンス内に表示されている日付を、表示順のまま取り出す
  # （一覧表示はスラッシュ区切りなので、ハイフン区切りの入力フォームの日付は拾わない）
  def displayed_labels
    response.body.scan(%r{\d{4}/\d{2}/\d{2}})
  end

  describe "GET /weight_records" do
    context "記録が上限を超えている場合" do
      before do
        # 上限+1件（0日前〜上限日前）を作成。いちばん古い1件が表示対象外になる
        create_records(0..limit)
        get weight_records_path
      end

      it "200 OKを返す" do
        expect(response).to have_http_status(:ok)
      end

      it "上限件数だけ表示される" do
        expect(displayed_labels.size).to eq(limit)
      end

      it "新しい記録から順に表示される" do
        expect(displayed_labels).to eq(expected_labels(limit))
      end

      it "上限を超えた古い記録は表示されない" do
        expect(response.body).not_to include(list_label(Date.current - limit))
      end

      it "表示されない古い記録もデータベースには残っている" do
        expect(user.weight_records.count).to eq(limit + 1)
        expect(user.weight_records.exists?(recorded_on: Date.current - limit)).to be true
      end
    end

    context "記録がちょうど上限件数の場合" do
      before do
        create_records(0...limit)
        get weight_records_path
      end

      it "すべての記録が新しい順に表示される" do
        expect(displayed_labels).to eq(expected_labels(limit))
      end
    end

    context "記録が上限未満の場合" do
      let(:record_count) { 3 }

      before do
        create_records(0...record_count)
        get weight_records_path
      end

      it "すべての記録が新しい順に表示される" do
        expect(displayed_labels).to eq(expected_labels(record_count))
      end
    end

    context "他のユーザーの記録がある場合" do
      before do
        # 自分は今日のみ、他人は5日前の記録を持つ
        create(:weight_record, user: user, recorded_on: Date.current)
        create(:weight_record, user: create(:user), recorded_on: Date.current - 5)
        get weight_records_path
      end

      it "自分の記録だけが表示される" do
        expect(displayed_labels).to eq(expected_labels(1))
      end
    end

    it "戻るリンクが表示され、保険の戻り先はマイページになる" do
      get weight_records_path
      expect(Capybara.string(response.body))
        .to have_css("a[data-controller='back-link'][href='#{mypage_path}']")
    end

    it "体重推移グラフは表示されない（マイページに移設済み）" do
      # 記録があってもグラフが出ないことを確かめるため、記録を1件作っておく
      create(:weight_record, user: user)
      get weight_records_path
      expect(response.body).not_to include('Chartkick["LineChart"]')
    end
  end

  describe "POST /weight_records" do
    context "他のユーザーが同じ日付の記録を持っている場合" do
      let(:other_record) { create(:weight_record, user: create(:user), weight: 50.0, recorded_on: Date.current) }

      before do
        other_record
        post weight_records_path, params: { weight_record: { weight: 60.5, recorded_on: Date.current } }
      end

      it "自分の記録として保存される" do
        expect(user.weight_records.find_by(recorded_on: Date.current).weight).to eq(60.5)
      end

      it "他人の記録は上書きされない" do
        expect(other_record.reload.weight).to eq(50.0)
      end
    end

    context "記録が上限を超えている状態で新しい記録を追加した場合" do
      let(:new_weight) { 60.5 }

      before do
        # 昨日以前の記録を上限+1件作っておく（今日の記録はまだない）
        create_records(1..(limit + 1))
        post weight_records_path, params: { weight_record: { weight: new_weight, recorded_on: Date.current } }
        follow_redirect!
      end

      it "追加した記録を含む最新の上限件数が表示される" do
        expect(displayed_labels).to eq(expected_labels(limit))
      end

      it "一覧に表示されなくなった古い記録も削除されない" do
        # 作成済みの上限+1件 + 追加した1件
        expect(user.weight_records.count).to eq(limit + 2)
      end
    end
  end
end
