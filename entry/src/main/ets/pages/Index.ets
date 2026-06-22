// 这是让游戏全屏显示的代码，你不用管什么意思，贴进去就行
import web_webview from '@ohos.web.webview';

@Entry
@Component
struct Index {
  controller: web_webview.WebviewController = new web_webview.WebviewController();

  build() {
    Column() {
"      Web({ src: $rawfile(""index.html""), controller: this.controller })"
        .width('100%')
        .height('100%')
        .javaScriptAccess(true)  // 允许游戏运行
        .domStorageAccess(true)  // 允许游戏存档
    }
    .width('100%')
    .height('100%')
  }
}
