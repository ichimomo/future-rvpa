# future-rvpa
<a href="http://www.jsfo.jp/contents/pdf/78-2/78-2-104.pdf">RVPA</a>の中で実装されている将来予測関数のコードを集めたプログラムになります．MSY管理基準値の計算コードなども入っています．関数の新機能や重要なバグ修正などをまとめたwikiページ　https://github.com/ichimomo/future-rvpa/wiki/%E5%B0%8F%E6%8A%80%E3%83%BB%E6%96%B0%E6%A9%9F%E8%83%BD%E9%9B%86 を作りました．

## githubを使ったことがない人の使い方
- 右上の「clone or downlowd」→「Download ZIP」からzipファイルをダウンロードしてください
- そうするとそのzipファイルにこのサイトで表示されているファイル群が全て入っています
- メインプログラムはfuture2.1.rですので、source("future2.1.r")として使って下さい
- **zipファイルが大きすぎる。future2.1.rだけ必要という人は：**　上のfuture2.1.rのファイル名をクリック　→　プログラムの中身が表示　→　右上の「Raw」ボタンを右クリック　→　名前をつけて保存

## バグ報告など
- できればissuesを使っての報告がありがたいです

## ファイル説明
- rvpa1.9.2.r : VPA計算用の関数群。管理は岡村さん担当になります。
- future2.1.r : 将来予測用の関数群。fit.SR関係は西嶋さん、それ以外は市野川の担当です。
- utilities.r : ggplot等を使って科学者会議用のグラフを作成するユーティリティ。市野川担当
- sample/ : サンプルコード置き場（Rのコードがあるのでこちらをいろいろ見てください）
- docs/ : htmlコード置き場（特に見る必要はありません）

## サンプルコード(sample/以下)
### simple: 2012年太平洋マアジの資源評価データを用いたfuture2.1.rの使用例
- 再生産関係のあてはめ
- 将来予測の実施
- MSY管理基準値の計算
- コードの解説：https://ichimomo.github.io/future-rvpa/future-doc-abc.html   
など

### make_report1: 科学者会議用のサンプルコード

内容はこちらのREADMEを読んでください
https://github.com/ichimomo/future-rvpa/tree/master/sample/make_report1

### SRR: 再生産関係推定のさいのモデル診断ツールの使用例
- 再生産関係のあてはめ
- 残差の正規性や自己相関のチェック
- ブートストラップや尤度プロファイルを用いたパラメータの信頼区間の推定
- コードの解説：https://ichimomo.github.io/future-rvpa/SRR-guidline.html   
など

### nsk2012: 2012年日本海スケトウダラの資源評価結果をもとにした実施例
- データと素のRコードのみです

