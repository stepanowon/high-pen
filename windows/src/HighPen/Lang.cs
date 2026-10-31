using System;
using System.Collections.Generic;

namespace HighPen
{
    // UI strings in Korean / Japanese / English. Cur is an index into Codes.
    static class Lang
    {
        public static readonly string[] Codes = { "ko", "ja", "en" };
        public static readonly string[] Names = { "한국어", "日本語", "English" };
        public static int Cur;

        static readonly Dictionary<string, string[]> Text = new Dictionary<string, string[]>
        {
            { "Spot",          new[] { "스팟", "スポット", "Spot" } },
            { "MouseSpot",     new[] { "마우스 스팟", "マウススポット", "Mouse spot" } },
            { "Pen",           new[] { "펜", "ペン", "Pen" } },
            { "Eraser",        new[] { "지우개", "消しゴム", "Eraser" } },
            { "EraserTip",     new[] { "지우개 상태에서 단축키를 한 번 더 누르면 전체 삭제", "消しゴム中にもう一度ショートカットを押すと全消去", "Press the shortcut again while erasing to clear all" } },
            { "Highlighter",   new[] { "형광펜", "蛍光ペン", "Highlighter" } },
            { "HighlightColor", new[] { "형광펜 색상", "蛍光ペンの色", "Highlighter color" } },
            { "HighlightSize", new[] { "형광펜 두께", "蛍光ペンの太さ", "Highlighter width" } },
            { "Board",         new[] { "칠판", "ボード", "Board" } },
            { "BoardTip",      new[] { "칠판 (흰색/검정/끄기)", "ボード (白/黒/オフ)", "Board (white/black/off)" } },
            { "WhiteBoard",    new[] { "흰 칠판", "白ボード", "White" } },
            { "BlackBoard",    new[] { "검은 칠판", "黒ボード", "Black" } },
            { "Undo",          new[] { "되돌리기", "元に戻す", "Undo" } },
            { "Clear",         new[] { "지우기", "全消去", "Clear" } },
            { "ClearTip",      new[] { "전체 지우기", "すべて消去", "Clear all" } },
            { "Zoom",          new[] { "확대", "拡大", "Zoom" } },
            { "ZoomTip",       new[] { "{0}배 확대", "{0}倍拡大", "{0}x zoom" } },
            { "ZoomLock",      new[] { "확대 화면 고정/해제", "拡大画面の固定/解除", "Lock/unlock zoomed view" } },
            { "ZoomLocked",    new[] { "확대 고정", "拡大固定", "Locked" } },
            { "Break",         new[] { "쉬는 시간", "休憩", "Break" } },
            { "BreakTip",      new[] { "쉬는 시간 타이머 시작/끝내기", "休憩タイマーの開始/終了", "Start/stop the break timer" } },
            { "BreakTitle",    new[] { "쉬는 시간", "休憩時間", "Break time" } },
            { "BreakOver",     new[] { "쉬는 시간이 끝났습니다", "休憩時間が終わりました", "The break is over" } },
            { "BreakEnds",     new[] { "{0}에 다시 시작합니다", "{0} に再開します", "Back at {0}" } },
            { "BreakLength",   new[] { "쉬는 시간: {0}", "休憩時間: {0}", "Break length: {0}" } },
            { "Minutes",       new[] { "{0}분", "{0}分", "{0} min" } },
            { "Hours",         new[] { "{0}시간", "{0}時間", "{0} h" } },
            { "HoursMinutes",  new[] { "{0}시간 {1}분", "{0}時間{1}分", "{0} h {1} min" } },
            { "ZoomFactor",    new[] { "확대 배율", "拡大倍率", "Zoom level" } },
            { "Bubble",        new[] { "말풍선", "吹き出し", "Note" } },
            { "Capture",       new[] { "캡처", "キャプチャ", "Capture" } },
            { "CaptureTip",    new[] { "화면과 필기를 PNG로 저장하고 클립보드에 복사", "画面と書き込みを PNG で保存してクリップボードにコピー", "Save the screen with ink as PNG and copy it to the clipboard" } },
            { "Saved",         new[] { "저장하고 클립보드에 복사했습니다\n{0}\n(클릭하면 폴더 열기)", "保存してクリップボードにコピーしました\n{0}\n(クリックでフォルダーを開く)", "Saved and copied to the clipboard\n{0}\n(click to open the folder)" } },
            { "SavedOnly",     new[] { "저장했습니다 (클립보드 복사는 실패)\n{0}\n(클릭하면 폴더 열기)", "保存しました (クリップボードへのコピーは失敗)\n{0}\n(クリックでフォルダーを開く)", "Saved (copying to the clipboard failed)\n{0}\n(click to open the folder)" } },
            { "CaptureFailed", new[] { "캡처하지 못했습니다", "キャプチャできませんでした", "Capture failed" } },
            { "ClickShow",     new[] { "클릭 표시", "クリック表示", "Show clicks" } },
            { "HotkeyFail",    new[] { "다른 프로그램이 사용 중이라 등록하지 못한 단축키:", "他のアプリが使用中のため登録できなかったショートカット:", "Shortcuts in use by another app (not registered):" } },
            { "Hotkeys",       new[] { "단축키 설정", "ショートカット設定", "Shortcuts" } },
            { "HotkeyHint",    new[] { "바꿀 항목을 누른 뒤 새 조합을 누르세요.\nEsc 취소, Delete 단축키 없애기", "変更する項目を押してから新しい組み合わせを押してください。\nEsc で取り消し、Delete でショートカットなし", "Click an item, then press the new combination.\nEsc cancels, Delete removes the shortcut." } },
            { "PressKeys",     new[] { "키를 누르세요…", "キーを押してください…", "Press keys…" } },
            { "NoKey",         new[] { "없음", "なし", "None" } },
            { "HotkeyNeedMod", new[] { "Ctrl 또는 Alt와 함께 눌러야 합니다 (F1~F24는 단독 사용 가능)", "Ctrl か Alt と一緒に押してください (F1~F24 は単独で使えます)", "Hold Ctrl or Alt as well (F1–F24 can be used alone)" } },
            { "HotkeyDup",     new[] { "이미 '{0}'에 쓰는 조합입니다", "すでに「{0}」で使っている組み合わせです", "Already used for \"{0}\"" } },
            { "HotkeyWaitHint", new[] { "눌러도 반응이 없으면 다른 프로그램이 이미 쓰는 조합입니다.", "押しても反応がない場合は、ほかのアプリがすでに使っている組み合わせです。", "If nothing happens, another app already uses that combination." } },
            { "HotkeyTaken",   new[] { "다른 프로그램이 사용 중인 조합입니다", "ほかのアプリが使用中の組み合わせです", "Another app is using this combination" } },
            { "ResetDefaults", new[] { "기본값으로", "既定に戻す", "Reset all" } },
            { "Cycle",         new[] { "순환", "切替", "cycle" } },
            { "Settings",      new[] { "설정", "設定", "Settings" } },
            { "Collapse",      new[] { "접기/펴기", "折りたたみ/展開", "Collapse/expand" } },
            { "Quit",          new[] { "종료", "終了", "Quit" } },
            { "About",         new[] { "정보", "情報", "About" } },
            { "AboutTip",      new[] { "저작자 및 라이선스 정보", "作者とライセンス情報", "Author and license" } },
            { "Tagline",       new[] { "비대면 강의용 Windows 펜 앱", "オンライン授業向け Windows ペンアプリ", "A Windows pen app for online lectures" } },
            { "Author",        new[] { "저작자", "作者", "Author" } },
            { "Email",         new[] { "이메일", "メール", "Email" } },
            { "Website",       new[] { "웹사이트", "Web サイト", "Website" } },
            { "License",       new[] { "라이선스", "ライセンス", "License" } },
            { "Close",         new[] { "닫기", "閉じる", "Close" } },
            { "Monitor",       new[] { "작동 모니터", "使用モニター", "Monitor" } },
            { "MonitorTip",    new[] { "모니터 {0}", "モニター {0}", "Monitor {0}" } },
            { "PenColor",      new[] { "펜 색상", "ペンの色", "Pen color" } },
            { "PenSize",       new[] { "펜 두께", "ペンの太さ", "Pen width" } },
            { "Pressure",      new[] { "필압 반영", "筆圧", "Pressure" } },
            { "On",            new[] { "켜짐", "オン", "on" } },
            { "Off",           new[] { "꺼짐", "オフ", "off" } },
            { "SpotColor",     new[] { "스팟 색상", "スポットの色", "Spot color" } },
            { "SpotSize",      new[] { "스팟 크기", "スポットの大きさ", "Spot size" } },
            { "Language",      new[] { "언어", "言語", "Language" } },
            { "UpdateCheck",   new[] { "업데이트 확인", "更新の確認", "Check for updates" } },
            { "UpdateCheckTip", new[] { "지금 새 버전이 있는지 확인 (시작할 때도 자동으로 확인합니다)", "今すぐ新しいバージョンを確認 (起動時にも自動で確認します)", "Look for a new version now (also checked at every start-up)" } },
            { "UpdateCheckStoreTip", new[] { "Microsoft Store에서 업데이트 확인 (Store 버전은 Store가 자동으로 업데이트합니다)", "Microsoft Store で更新を確認 (Store 版は Store が自動で更新します)", "Check for updates in the Microsoft Store (the Store keeps this version up to date)" } },
            { "UpdateLatest",  new[] { "최신 버전입니다 (v{0})", "最新バージョンです (v{0})", "HighPen is up to date (v{0})" } },
            { "UpdateCheckFailed", new[] { "업데이트를 확인하지 못했습니다. 인터넷 연결을 확인하세요.", "更新を確認できませんでした。インターネット接続を確認してください。", "Could not check for updates. Check your internet connection." } },
            { "UpdateTitle",   new[] { "새 버전이 있습니다", "新しいバージョンがあります", "A new version is available" } },
            { "UpdateText",    new[] { "HighPen v{0}이(가) 나왔습니다. (현재 v{1})\nMicrosoft Store에서 서명된 버전을 설치할 수 있고, Store 버전은 앞으로 자동으로 업데이트됩니다.", "HighPen v{0} が公開されました。(現在 v{1})\nMicrosoft Store から署名済みのバージョンをインストールでき、Store 版は今後自動で更新されます。", "HighPen v{0} is out. (You have v{1}.)\nInstall the signed version from the Microsoft Store; the Store keeps it up to date from then on." } },
            { "UpdateHint",    new[] { "Store 버전을 설치한 뒤에는 지금 쓰는 HighPen을 종료하고 Windows 설정의 '설치된 앱'에서 제거하세요. (설치 없이 HighPen.exe로 쓰고 있다면 그 파일을 지우면 됩니다.)", "Store 版をインストールしたら、今使っている HighPen を終了し、Windows の設定の「インストールされているアプリ」から削除してください。(インストールせずに HighPen.exe を使っている場合は、そのファイルを削除してください。)", "After installing the Store version, quit this HighPen and remove it under Installed apps in Windows Settings. (If you run HighPen.exe without installing, just delete that file.)" } },
            { "UpdateNotes",   new[] { "변경 내용 보기", "変更内容を見る", "What's new" } },
            { "UpdateStore",   new[] { "Microsoft Store에서 받기", "Microsoft Store で入手", "Get it from the Store" } },
            { "UpdateLater",   new[] { "나중에", "後で", "Later" } },
            { "Red",           new[] { "빨강", "赤", "Red" } },
            { "Orange",        new[] { "주황", "オレンジ", "Orange" } },
            { "Yellow",        new[] { "노랑", "黄", "Yellow" } },
            { "Green",         new[] { "초록", "緑", "Green" } },
            { "Blue",          new[] { "파랑", "青", "Blue" } },
            { "Purple",        new[] { "보라", "紫", "Purple" } },
            { "Black",         new[] { "검정", "黒", "Black" } },
            { "White",         new[] { "흰색", "白", "White" } },
        };

        public static string T(string key) { return Text[key][Cur]; }

        // Saved code, or English when nothing (or an unsupported code) is saved.
        public static int FromCode(string code)
        {
            int i = Array.IndexOf(Codes, code);
            return i < 0 ? 2 : i;
        }
    }
}
