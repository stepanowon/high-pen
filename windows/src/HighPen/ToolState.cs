namespace HighPen
{
    // Which tool is in use and which board is shown. Plain state with the toggle rules; whoever changes it
    // applies the result to the windows afterwards.
    class ToolState
    {
        public const int NoBoard = 0, WhiteBoard = 1, BlackBoard = 2;

        // Pen mode: the overlay takes input (pen, highlighter, eraser or speech bubbles); otherwise clicks go to the desktop.
        public bool PenMode { get; private set; }
        public bool Eraser { get; private set; }
        public bool TextMode { get; private set; }
        public bool Highlighter { get; private set; }
        public int Board { get; private set; }

        public bool PenActive { get { return PenMode && !Eraser && !TextMode && !Highlighter; } }
        public bool HighlighterActive { get { return PenMode && !Eraser && !TextMode && Highlighter; } }

        public void TogglePen()
        {
            if (PenActive) { SetPen(false); return; }
            Eraser = false;
            TextMode = false;
            Highlighter = false;
            SetPen(true);
        }

        public void ToggleHighlighter()
        {
            if (HighlighterActive) { SetPen(false); return; }
            Eraser = false;
            TextMode = false;
            Highlighter = true;
            SetPen(true);
        }

        public void ToggleEraser()
        {
            Eraser = !Eraser;
            TextMode = false;
            if (Eraser) PenMode = true;
        }

        public void ToggleText()
        {
            TextMode = !TextMode;
            if (TextMode) { PenMode = true; Eraser = false; }
        }

        public void EndText() { TextMode = false; }

        // none -> white -> black -> none; a board always comes up with the pen.
        public void CycleBoard()
        {
            Board = (Board + 1) % OverlayWindow.PageCount;
            if (Board != NoBoard) { PenMode = true; Eraser = false; TextMode = false; }
        }

        // Leaving pen mode also drops the eraser, highlighter, text mode and board.
        void SetPen(bool on)
        {
            PenMode = on;
            if (!on) { TextMode = false; Eraser = false; Highlighter = false; Board = NoBoard; }
        }
    }
}
