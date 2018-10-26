# future-rvpa
<a href="http://www.jsfo.jp/contents/pdf/78-2/78-2-104.pdf">RVPA</a>の中で実装されている将来予測関数のコードを集めたプログラムになります．MSY管理基準値の計算コードなども入っています．

- **future2.1.r** プログラムの本体です
- **sample/** 2011年までの太平洋マアジ資源評価結果をもとにMSY管理基準値を計算するコード（Rmdコード，計算に使うcsvファイルなど）
     - 上記のフォルダ内のRコードの解説 https://ichimomo.github.io/future-rvpa/future-doc-abc.html 
     - 特に再生産関係の診断に関する解説 https://ichimomo.github.io/future-rvpa/SRR-guidline.html 

## githubを使ったことがない人の使い方
- 右上の「clone or downlowd」→「Download ZIP」からzipファイルをダウンロードしてください
- そうするとそのzipファイルにこのサイトで表示されているファイル群が全て入っています
- メインプログラムはfuture2.1.rですので、source("future2.1.r")として使って下さい

## バグ報告など
- できればissuesを使っての報告がありがたいです

