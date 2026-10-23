import { Controller } from "@hotwired/stimulus"

// アプリ内で1回以上画面遷移していれば、戻り先がある
const MIN_VISIT_COUNT_TO_GO_BACK = 1

// 「戻る」リンクを、ブラウザの戻るボタンと同じ動きにするコントローラー
// 戻り先が無いとき（URL直接アクセスなど）は何もせず、リンク本来の遷移（保険の戻り先）に任せる
export default class extends Controller {
  goBack(event) {
    if (!this.hasPreviousPageInApp()) return

    // リンクの遷移を止めて、履歴を1つ戻る
    event.preventDefault()
    window.history.back()
  }

  // Turboが履歴に記録している「アプリ内での遷移回数」で、戻り先があるか判定する
  // history.length は Chrome の「新しいタブ」画面なども数えてしまうため使わない
  hasPreviousPageInApp() {
    const visitCount = window.history.state?.turbo?.restorationIndex || 0
    return visitCount >= MIN_VISIT_COUNT_TO_GO_BACK
  }
}
