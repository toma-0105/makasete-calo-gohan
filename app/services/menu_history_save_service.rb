# 献立を履歴に保存するサービス
# 同じユーザー・同じ日付の保存済み献立がある場合は、そちらを未保存に戻して置き換える
class MenuHistorySaveService
  # 保存した献立と、置き換えた（未保存に戻した）件数を返す
  Result = Struct.new(:menu, :replaced_count)

  def initialize(user, menu)
    @user = user
    @menu = menu
  end

  def save!
    replaced_count = 0

    # 「古い方を戻す」と「新しい方を保存する」を同一トランザクションにまとめ、
    # 途中で失敗しても片方だけ反映されて履歴が0件になるのを防ぐ
    ApplicationRecord.transaction do
      # 対象自身は除外する（同じ献立の保存ボタンを再度押しても置き換え扱いにしない）
      replaced_count = @user.menus.saved.where(date: @menu.date).where.not(id: @menu.id).update_all(saved: false)
      @menu.update!(saved: true)
    end

    Result.new(@menu, replaced_count)
  end
end
