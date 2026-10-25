using System;
using System.IO;

namespace HighPen
{
    // The saved file (null when nothing could be saved) and whether the image also reached the clipboard.
    class CaptureResult
    {
        public string Path;
        public bool Copied;
    }

    interface IScreenCapture
    {
        CaptureResult Capture(System.Drawing.Rectangle bounds);
    }

    // Saves a screen area as Pictures\HighPen\HighPen_<time>.png and copies it to the clipboard.
    class PngScreenCapture : IScreenCapture
    {
        public CaptureResult Capture(System.Drawing.Rectangle b)
        {
            CaptureResult r = new CaptureResult();
            try
            {
                using (System.Drawing.Bitmap bmp = new System.Drawing.Bitmap(b.Width, b.Height))
                {
                    using (System.Drawing.Graphics g = System.Drawing.Graphics.FromImage(bmp))
                        g.CopyFromScreen(b.Left, b.Top, 0, 0, b.Size); // DWM composition includes the layered ink/board overlay
                    string dir = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "HighPen");
                    Directory.CreateDirectory(dir);
                    r.Path = System.IO.Path.Combine(dir, "HighPen_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".png");
                    bmp.Save(r.Path, System.Drawing.Imaging.ImageFormat.Png);
                    try { System.Windows.Forms.Clipboard.SetImage(bmp); r.Copied = true; } catch { }
                }
            }
            catch { r.Path = null; }
            return r;
        }
    }
}
