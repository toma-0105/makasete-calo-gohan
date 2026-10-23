import { Controller } from "@hotwired/stimulus"

// 履歴が1件だけ＝このページが最初の画面（戻る先が無い）
const FIRST_PAGE_HISTORY_LENGTH = 1

// 「戻る」リンクを、ブラウザの戻るボタンと同じ動きにするコントローラー
// 履歴が無いとき（URL直接アクセスなど）は何もせず、リンク本来の遷移（保険の戻り先）に任せる
export default class extends Controller {
  goBack(event) {
    if (window.history.length <= FIRST_PAGE_HISTORY_LENGTH) return

    // リンクの遷移を止めて、履歴を1つ戻る
    event.preventDefault()
    window.history.back()
  }
}
