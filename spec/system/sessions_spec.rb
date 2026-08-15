require "rails_helper"

RSpec.describe "ログイン", type: :system do
  let(:user) { create(:user, password: "password123") }

  it "トップページからログインし、マイページに遷移する" do
    visit root_path
    click_link "ログイン"
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"
    expect(page).to have_current_path(mypage_path)
    expect(page).to have_content("#{user.name}さんのマイページ")

    expect(page).to have_link("マイページ")
    expect(page).to have_link("ログアウト")
  end
end
