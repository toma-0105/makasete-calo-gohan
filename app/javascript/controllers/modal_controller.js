import { Controller } from "@hotwired/stimulus"

// 画面表示と同時に <dialog> をモーダルとして開くコントローラー
// 閉じる操作（×ボタン・背景クリック・Escキー）は <dialog> の標準機能に任せる
export default class extends Controller {
  connect() {
    // Turboの「戻る」操作などで既に開いている場合は、二重に開いてエラーになるのを防ぐ
    if (!this.element.open) {
      this.element.showModal()
    }
  }
}
