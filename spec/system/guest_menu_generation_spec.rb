require "rails_helper"

RSpec.describe "ゲストの献立生成", type: :system do
  before do
    # 献立に使う料理を用意する。一品料理は作らず、毎回「主食+主菜+副菜(+汁物)」の基本形にする
    %i[staple side_dish soup].each { |category| create(:meal_master, meal_timing: :breakfast, category: category) }
    # 朝食の主菜は1件だけなので必ず選ばれる。献立が表示されたかの目印にする
    # （名前にグラム数を入れると、倍率がかかったときに表示が書き換わるため入れない）
    create(:meal_master, name: "目印の焼き鮭", meal_timing: :breakfast, category: :main_dish)
    # 昼食と夕食は同じ料理を選ばない仕組みのため、2件ずつ用意する
    %i[staple main_dish side_dish soup].each do |category|
      create_list(:meal_master, 2, meal_timing: :lunch_or_dinner, category: category)
    end
  end

  it "ゲストログインからTDEE診断・献立生成まで進み、献立が表示される" do
    visit root_path
    click_button "ゲストでログイン"
    expect(page).to have_content("ゲストとしてログインしました")

    # アレルギーは選ばずにTDEE診断へ進む
    click_link "アレルギーはないです"

    fill_in "身長 (cm)", with: "165"
    fill_in "体重 (kg)", with: "60"
    fill_in "年齢", with: "30"
    choose "女性"
    select "週1〜3回運動する", from: "活動レベル"
    click_button "計算する"
    expect(page).to have_content("TDEE診断が完了しました")

    click_button "献立を生成する"
    expect(page).to have_content("1日分の献立")

    # 献立は日付ごとに閉じた<details>で表示され、rack_testでは閉じた中身が「見えない」扱いになる
    # そのため、日付（summary）をクリックして開いてから料理名を確かめる
    find("summary").click
    expect(page).to have_content("目印の焼き鮭")
  end
end
