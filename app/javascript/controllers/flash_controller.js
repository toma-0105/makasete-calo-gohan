import { Controller } from "@hotwired/stimulus"

// フラッシュメッセージの消え方を制御するコントローラー
// notice（成功）は一定時間後に自動でフェードアウトし、alert（エラー）は×ボタンで閉じるまで残す

// 自動で消えるまでの待ち時間（読み終わる余裕を持たせて4秒）
const AUTO_DISMISS_DELAY_MS = 4000
// フェードアウトにかける時間（Tailwindのduration-300と合わせる）
const FADE_DURATION_MS = 300

export default class extends Controller {
  // 自動消去するかどうかをビュー側のdata属性で切り替える
  static values = { autoDismiss: Boolean }

  connect() {
    if (this.autoDismissValue) {
      this.timeoutId = setTimeout(() => this.close(), AUTO_DISMISS_DELAY_MS)
    }
  }

  disconnect() {
    // ページ遷移で要素が先に消えた場合に備え、予約済みのタイマーを解除する
    clearTimeout(this.timeoutId)
  }

  close() {
    // opacityを0にしてふわっと消し、アニメーション完了後に要素ごと取り除く
    this.element.classList.add("transition-opacity", "duration-300", "opacity-0")
    setTimeout(() => this.element.remove(), FADE_DURATION_MS)
  }
}
