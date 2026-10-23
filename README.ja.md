# HighPen

- **한국어:** [한국어로 된 문서는 여기를 보세요.](README.md)
- **English:** [Read this document in English.](README.en.md)
- **日本語:** 現在ご覧のドキュメントです。

オンライン授業向けのペンアプリです。画面に直接書き込んだり、マウスポインターをスポットで強調したり、画面を拡大したり、ボードを表示したりできます。

![HighPen のツールバーとマウススポット](screen/전체화면1.png)

## 対応プラットフォーム

| プラットフォーム | 状態 | ドキュメント |
|---|---|---|
| Windows 10/11 | 配布中 (Microsoft Store、winget、exe) | [インストールと使い方](windows/README.ja.md) |
| macOS 14 以降 | プレリリース (DMG) | [ビルドと使い方](macos/README.ja.md) |

### Windows

[<img src="https://get.microsoft.com/images/ja%20dark.svg" width="200" alt="Microsoft から入手"/>](https://apps.microsoft.com/detail/9PDG1QN5QSL3?mode=direct)

Microsoft Store からのインストールをおすすめします。winget、インストール不要の exe、インストーラーなどほかの方法と機能の説明は [Windows 版ドキュメント](windows/README.ja.md)をご覧ください。

### macOS

**[HighPen-1.1.0.dmg をダウンロード](https://github.com/stepanowon/high-pen/releases/download/macos-v1.1.0/HighPen-1.1.0.dmg)** (プレリリース [macos-v1.1.0](https://github.com/stepanowon/high-pen/releases/tag/macos-v1.1.0))

macOS 14 (Sonoma) 以降、Apple シリコンと Intel の Mac に対応しています。DMG を開き、HighPen を Applications フォルダーにドラッグするとインストールされます。まだ Apple の公証を受けていないため、**初めて開く前に**ターミナルで次のコマンドを実行すると警告なしで開けます。(コマンドなしで開き、警告で**ゴミ箱に入れる**を押すとアプリが削除されます。)

```sh
xattr -dr com.apple.quarantine /Applications/HighPen.app
```

ビルド方法、機能とショートカット、権限の設定は [macOS 版ドキュメント](macos/README.ja.md)をご覧ください。

## リポジトリ構成

| パス | 内容 |
|---|---|
| `windows/` | Windows アプリ (ソース、ビルドスクリプト、実行ファイル、Store パッケージ、配布記録) |
| `macos/` | macOS アプリ (ソース、ビルド・DMG パッケージ作成スクリプト、ドキュメント) |
| `screen/` | ドキュメント用のスクリーンショットと紹介動画 |
| `PRIVACY.md` | プライバシーポリシー |

## プライバシー

このプログラムは、ユーザーまたはインストール・運用する人が明示的に要求しない限り、いかなる情報もほかのネットワークシステムに送信しません。詳しくは[プライバシーポリシー](PRIVACY.md#日本語)をご覧ください。

## ライセンス

[MIT License](LICENSE) で公開しています。商用利用を含め自由に使用・改変・再配布できますが、再配布の際は著作権表示とライセンス文を含める必要があります。
