import Cocoa

// ---------- strings (Korean / Japanese / English) ----------

enum Lang {
    static let codes = ["ko", "ja", "en"]
    static let names = ["한국어", "日本語", "English"]
    static var cur = 2

    static let text: [String: [String]] = [
        "Spot": ["스팟", "スポット", "Spot"],
        "MouseSpot": ["마우스 스팟", "マウススポット", "Mouse spot"],
        "Pen": ["펜", "ペン", "Pen"],
        "Eraser": ["지우개", "消しゴム", "Eraser"],
        "EraserTip": ["지우개 상태에서 단축키를 한 번 더 누르면 전체 삭제", "消しゴム中にもう一度ショートカットを押すと全消去", "Press the shortcut again while erasing to clear all"],
        "Highlighter": ["형광펜", "蛍光ペン", "Highlighter"],
        "HighlightColor": ["형광펜 색상", "蛍光ペンの色", "Highlighter color"],
        "HighlightSize": ["형광펜 두께", "蛍光ペンの太さ", "Highlighter width"],
        "Board": ["칠판", "ボード", "Board"],
        "BoardTip": ["칠판 (흰색/검정/끄기)", "ボード (白/黒/オフ)", "Board (white/black/off)"],
        "WhiteBoard": ["흰 칠판", "白ボード", "White"],
        "BlackBoard": ["검은 칠판", "黒ボード", "Black"],
        "Bubble": ["말풍선", "吹き出し", "Note"],
        "BubbleTip": ["클릭한 곳에 글 붙이기. Enter 확정, Shift+Enter 줄바꿈, Esc 취소", "クリックした所に文字を貼る。Enter で確定、Shift+Enter で改行、Esc で取り消し", "Click to place text. Enter confirms, Shift+Enter adds a line, Esc cancels"],
        "Undo": ["되돌리기", "元に戻す", "Undo"],
        "Clear": ["지우기", "全消去", "Clear"],
        "ClearTip": ["전체 지우기", "すべて消去", "Clear all"],
        "Zoom": ["확대", "拡大", "Zoom"],
        "ZoomFactor": ["확대 배율", "拡大倍率", "Zoom level"],
        "Capture": ["캡처", "キャプチャ", "Capture"],
        "CaptureTip": ["화면과 필기를 PNG로 저장하고 클립보드에 복사", "画面と書き込みを PNG で保存してクリップボードにコピー", "Save the screen with ink as PNG and copy it to the clipboard"],
        "Saved": ["저장하고 클립보드에 복사했습니다\n%@\n(클릭하면 Finder에서 보기)", "保存してクリップボードにコピーしました\n%@\n(クリックで Finder に表示)", "Saved and copied to the clipboard\n%@\n(click to show in Finder)"],
        "CaptureFailed": ["캡처하지 못했습니다", "キャプチャできませんでした", "Capture failed"],
        "NeedPermission": ["화면 기록 권한이 필요합니다.\n시스템 설정 > 개인정보 보호 및 보안 > 화면 및 시스템 오디오 녹음에서 HighPen을 켠 뒤 HighPen을 종료하고 다시 실행하세요.\n(클릭하면 설정 열기)",
                           "画面収録の許可が必要です。\nシステム設定 > プライバシーとセキュリティ > 画面とシステムオーディオの録音 で HighPen をオンにしてから、HighPen を終了して再起動してください。\n(クリックで設定を開く)",
                           "Screen recording permission is needed.\nTurn on HighPen in System Settings > Privacy & Security > Screen & System Audio Recording, then quit and reopen HighPen.\n(click to open Settings)"],
        "HotkeyFail": ["다른 프로그램이 사용 중이라 등록하지 못한 단축키:", "他のアプリが使用中のため登録できなかったショートカット:", "Shortcuts in use by another app (not registered):"],
        "Hotkeys": ["단축키 설정", "ショートカット設定", "Shortcuts"],
        "HotkeyHint": ["바꿀 항목을 누른 뒤 새 조합을 누르세요.\nEsc 취소, Delete 단축키 없애기", "変更する項目を押してから新しい組み合わせを押してください。\nEsc で取り消し、Delete でショートカットなし", "Click an item, then press the new combination.\nEsc cancels, Delete removes the shortcut."],
        "PressKeys": ["키를 누르세요…", "キーを押してください…", "Press keys…"],
        "NoKey": ["없음", "なし", "None"],
        "HotkeyNeedMod": ["⌃, ⌥ 또는 ⌘와 함께 눌러야 합니다 (F1~F20은 단독 사용 가능)", "⌃、⌥ または ⌘ と一緒に押してください (F1~F20 は単独で使えます)", "Hold ⌃, ⌥ or ⌘ as well (F1–F20 can be used alone)"],
        "HotkeyDup": ["이미 '%@'에 쓰는 조합입니다", "すでに「%@」で使っている組み合わせです", "Already used for \"%@\""],
        "HotkeyWaitHint": ["눌러도 반응이 없으면 다른 프로그램이 이미 쓰는 조합입니다.", "押しても反応がない場合は、ほかのアプリがすでに使っている組み合わせです。", "If nothing happens, another app already uses that combination."],
        "HotkeyTaken": ["다른 프로그램이 사용 중인 조합입니다", "ほかのアプリが使用中の組み合わせです", "Another app is using this combination"],
        "ResetDefaults": ["기본값으로", "既定に戻す", "Reset all"],
        "About": ["정보", "情報", "About"],
        "AboutTip": ["저작자 및 라이선스 정보", "作者とライセンス情報", "Author and license"],
        "Tagline": ["비대면 강의용 macOS 펜 앱", "オンライン授業向け macOS ペンアプリ", "A macOS pen app for online lectures"],
        "Author": ["저작자", "作者", "Author"],
        "Email": ["이메일", "メール", "Email"],
        "License": ["라이선스", "ライセンス", "License"],
        "Close": ["닫기", "閉じる", "Close"],
        "Cycle": ["순환", "切替", "cycle"],
        "Settings": ["설정", "設定", "Settings"],
        "Collapse": ["접기/펴기", "折りたたみ/展開", "Collapse/expand"],
        "Quit": ["종료", "終了", "Quit"],
        "Monitor": ["작동 모니터", "使用モニター", "Monitor"],
        "PenColor": ["펜 색상", "ペンの色", "Pen color"],
        "PenSize": ["펜 두께", "ペンの太さ", "Pen width"],
        "Pressure": ["필압 반영", "筆圧", "Pressure"],
        "SpotColor": ["스팟 색상", "スポットの色", "Spot color"],
        "SpotSize": ["스팟 크기", "スポットの大きさ", "Spot size"],
        "Language": ["언어", "言語", "Language"],
        "Website": ["웹사이트", "Web サイト", "Website"],
        "Red": ["빨강", "赤", "Red"],
        "Orange": ["주황", "オレンジ", "Orange"],
        "Yellow": ["노랑", "黄", "Yellow"],
        "Green": ["초록", "緑", "Green"],
        "Blue": ["파랑", "青", "Blue"],
        "Purple": ["보라", "紫", "Purple"],
        "Black": ["검정", "黒", "Black"],
        "White": ["흰색", "白", "White"],
    ]

    static func t(_ key: String) -> String { text[key]?[cur] ?? key }

    // Saved code, else the system language, else English.
    static func index(_ code: String?) -> Int {
        let c = code ?? String((Locale.preferredLanguages.first ?? "en").prefix(2))
        return codes.firstIndex(of: c) ?? 2
    }
}
