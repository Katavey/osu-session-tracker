using System;
using System.IO;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Text.RegularExpressions;

public static class SessionTheme {
    public static string FontName="Comic Sans MS";
    public static Color Accent=Color.FromArgb(239,105,164);
    public static Color PanelColor=Color.FromArgb(38,31,46);
    public static Color CardColor=Color.FromArgb(43,36,51);
    public static void DrawScoreBadge(Graphics g,int x,int y,string category){
        if(String.IsNullOrEmpty(category))return;
        bool best=category=="best";Color color=best?Color.FromArgb(255,211,127):Color.FromArgb(126,204,255);
        using(var pen=new Pen(color,1.4f))using(var brush=new SolidBrush(color))using(var font=new Font("Segoe UI",6.2f,FontStyle.Bold)){
            if(best){var points=new PointF[10];for(int i=0;i<10;i++){double a=-Math.PI/2+i*Math.PI/5;double radius=i%2==0?5:2.2;points[i]=new PointF(x+5+(float)(Math.Cos(a)*radius),y+6+(float)(Math.Sin(a)*radius));}g.FillPolygon(brush,points);}
            else{g.DrawArc(pen,x+1,y+1,9,9,205,315);g.DrawLines(pen,new Point[]{new Point(x,y+1),new Point(x,y+5),new Point(x+4,y+5)});g.DrawLines(pen,new Point[]{new Point(x+6,y+3),new Point(x+6,y+6),new Point(x+8,y+7)});}
            g.DrawString(best?"BEST":"RECENT",font,brush,x+12,y);
        }
    }
    public static void PaintParent(Control child,Graphics g){
        var parent=child.Parent as SessionForm;
        if(parent==null){g.Clear(child.Parent==null?child.BackColor:child.Parent.BackColor);return;}
        var saved=g.Save();g.TranslateTransform(-child.Left,-child.Top);parent.PaintSurface(g);g.Restore(saved);
    }
    [DllImport("dwmapi.dll")] static extern int DwmSetWindowAttribute(IntPtr hwnd,int attr,ref int value,int size);
    public static GraphicsPath Rounded(Rectangle r,int radius){
        var p=new GraphicsPath();int d=Math.Max(2,Math.Min(radius*2,Math.Min(r.Width,r.Height)));
        p.AddArc(r.Left,r.Top,d,d,180,90);p.AddArc(r.Right-d,r.Top,d,d,270,90);
        p.AddArc(r.Right-d,r.Bottom-d,d,d,0,90);p.AddArc(r.Left,r.Bottom-d,d,d,90,90);p.CloseFigure();return p;
    }
    static void ApplyRegion(Control c,int radius){
        if(c.Width<2||c.Height<2)return;
        using(var p=Rounded(new Rectangle(0,0,c.Width,c.Height),radius)){
            var old=c.Region;c.Region=new Region(p);if(old!=null)old.Dispose();
        }
    }
    public static void Round(Control c,int radius){ApplyRegion(c,radius);c.Resize+=(s,e)=>ApplyRegion(c,radius);}
    public static void RoundWindow(Form form){
        form.HandleCreated+=(s,e)=>{
            try{int pref=2;if(DwmSetWindowAttribute(form.Handle,33,ref pref,4)==0)return;}catch{}
            Round(form,18);
        };
    }
}
public class SessionForm : Form {
    public Image Wallpaper;
    public int DimPercent=67;
    public SessionForm(){DoubleBuffered=true;SetStyle(ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.ResizeRedraw,true);}
    public void PaintSurface(Graphics g){
        g.Clear(BackColor);
        if(Wallpaper==null||ClientSize.Width<1||ClientSize.Height<1)return;
        float scale=Math.Max((float)ClientSize.Width/Wallpaper.Width,(float)ClientSize.Height/Wallpaper.Height);
        float w=ClientSize.Width/scale,h=ClientSize.Height/scale;
        g.DrawImage(Wallpaper,ClientRectangle,(Wallpaper.Width-w)/2,(Wallpaper.Height-h)/2,w,h,GraphicsUnit.Pixel);
        using(var overlay=new SolidBrush(Color.FromArgb(Math.Max(0,Math.Min(255,DimPercent*255/100)),20,15,29)))g.FillRectangle(overlay,ClientRectangle);
    }
    protected override void OnPaintBackground(PaintEventArgs e){PaintSurface(e.Graphics);}
    protected override void Dispose(bool disposing){if(disposing&&Wallpaper!=null){Wallpaper.Dispose();Wallpaper=null;}base.Dispose(disposing);}
}
public static class MascotAudio {
    static System.Media.SoundPlayer player;
    public static void Stop(){if(player!=null){player.Stop();player.Dispose();player=null;}}
    public static bool Play(string path){
        Stop();try{player=new System.Media.SoundPlayer(System.IO.Path.GetFullPath(path));player.Load();player.Play();return true;}catch{Stop();return false;}
    }
    public static int Duration(string path){
        using(var test=new System.Media.SoundPlayer(System.IO.Path.GetFullPath(path)))test.Load();
        using(var reader=new System.IO.BinaryReader(System.IO.File.OpenRead(path))){
            if(new string(reader.ReadChars(4))!="RIFF")return 0;
            reader.ReadInt32();if(new string(reader.ReadChars(4))!="WAVE")return 0;
            int rate=0;
            while(reader.BaseStream.Position+8<=reader.BaseStream.Length){
                string tag=new string(reader.ReadChars(4));int length=reader.ReadInt32();long next=reader.BaseStream.Position+length+(length%2);
                if(tag=="fmt "&&length>=16){reader.ReadInt16();reader.ReadInt16();reader.ReadInt32();rate=reader.ReadInt32();}
                if(tag=="data"&&rate>0)return (int)((long)length*1000/rate);
                reader.BaseStream.Position=next;
            }
        }
        return 0;
    }
}

public class SessionButton : Button {
    bool hover;
    public bool Primary {get;set;}
    public SessionButton() {
        FlatStyle=FlatStyle.Flat; FlatAppearance.BorderSize=0;
        Cursor=Cursors.Hand; DoubleBuffered=true;
    }
    protected override void OnMouseEnter(EventArgs e){hover=true; Invalidate();base.OnMouseEnter(e);}
    protected override void OnMouseLeave(EventArgs e){hover=false;Invalidate();base.OnMouseLeave(e);}
    protected override void OnPaint(PaintEventArgs e){
        SessionTheme.PaintParent(this,e.Graphics);
        e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
        Rectangle r=new Rectangle(1,1,Width-3,Height-3);
        using(var path=new GraphicsPath()){
            int d=18;
            path.AddArc(r.Left,r.Top,d,d,180,90);path.AddArc(r.Right-d,r.Top,d,d,270,90);
            path.AddArc(r.Right-d,r.Bottom-d,d,d,0,90);path.AddArc(r.Left,r.Bottom-d,d,d,90,90);path.CloseFigure();
            Color c=!Enabled?Color.FromArgb(40,38,48):Primary?(hover?ControlPaint.Light(SessionTheme.Accent):SessionTheme.Accent):(hover?ControlPaint.Light(SessionTheme.PanelColor):SessionTheme.PanelColor);
            using(var b=new SolidBrush(c))e.Graphics.FillPath(b,path);
        }
        TextRenderer.DrawText(e.Graphics,Text,Font,ClientRectangle,!Enabled?Color.Gray:Primary?Color.FromArgb(30,20,33):Color.FromArgb(238,228,241),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter);
    }
}
public class SessionLabel : Label {
    public SessionLabel(){DoubleBuffered=true;BackColor=Color.Transparent;}
    protected override void OnPaintBackground(PaintEventArgs e){
        SessionTheme.PaintParent(this,e.Graphics);
        e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
        using(var path=SessionTheme.Rounded(ClientRectangle,16))
        using(var brush=new SolidBrush(BackColor))e.Graphics.FillPath(brush,path);
    }
}
public class ScoreEntry {
    public string Map,Mods,Rank,Time,Hits,Background,Url,Key,Badge;
    public double Pp,Accuracy,Stars,FcPp,Rate;
    public int Combo;
    public bool Fc;
    public Image Cover;
}
public class ScoreCards : ScrollableControl {
    public static bool English;
    Font title,small,big,rank;
    public readonly List<ScoreEntry> Items=new List<ScoreEntry>();
    public static string IconDirectory;
    Dictionary<string,Image> icons=new Dictionary<string,Image>();
    bool updating;
    public int RowHeight=110;
    public bool Horizontal;
    public int CardWidth=560;
    public void SetHorizontal(bool enabled,int width){Horizontal=enabled;CardWidth=width;UpdateExtent();}
    void UpdateExtent(){AutoScrollMinSize=Horizontal?new Size(Items.Count*CardWidth,0):new Size(0,Items.Count*RowHeight);Invalidate();}
    protected override void OnMouseWheel(MouseEventArgs e){if(Horizontal){TopIndex=Math.Max(0,Math.Min(Items.Count-1,TopIndex+(e.Delta<0?1:-1)));}else base.OnMouseWheel(e);}

    public bool AnimateNewScores=true;
    readonly System.Windows.Forms.Timer animationTimer=new System.Windows.Forms.Timer();
    readonly System.Diagnostics.Stopwatch animationClock=new System.Diagnostics.Stopwatch();
    string animationKey;
    ToolTip linkTip=new ToolTip();
    string tipText;
    public event EventHandler ScoreClicked;
    public string ClickedUrl {get;private set;}
    public int TopIndex {get{return Horizontal?Math.Max(0,-AutoScrollPosition.X/CardWidth):Math.Max(0,-AutoScrollPosition.Y/RowHeight);}set{AutoScrollPosition=Horizontal?new Point(Math.Max(0,value)*CardWidth,0):new Point(0,Math.Max(0,value)*RowHeight);}}
    public void BeginUpdate(){updating=true;}
    public void EndUpdate(){updating=false;UpdateExtent();}
    public int CardAt(Point point){
        if(point.X<0||point.X>=ClientSize.Width||point.Y<0||point.Y>=ClientSize.Height)return -1;
        if(Horizontal){int px=point.X-AutoScrollPosition.X,indexX=px/CardWidth;return indexX>=0&&indexX<Items.Count&&point.Y>=3&&point.Y<RowHeight-6?indexX:-1;}
        int y=point.Y-AutoScrollPosition.Y,index=y/RowHeight;
        return index>=0&&index<Items.Count&&y%RowHeight>=3&&y%RowHeight<RowHeight-6?index:-1;
    }
    protected override void OnMouseMove(MouseEventArgs e){
        base.OnMouseMove(e);int index=CardAt(e.Location);
        string url=index>=0?Items[index].Url:null;
        Cursor=String.IsNullOrEmpty(url)?Cursors.Default:Cursors.Hand;
        string text=String.IsNullOrEmpty(url)?(English?"No link for this local result":"Ссылка недоступна для локального результата"):url.Contains("/scores/")?(English?"Open score in browser":"Открыть скор в браузере"):(English?"Score ID unavailable — open beatmap":"ID скора ещё нет — открыть карту");
        if(index<0)text="";
        if(text!=tipText){tipText=text;linkTip.SetToolTip(this,text);}
    }
    protected override void OnMouseClick(MouseEventArgs e){
        base.OnMouseClick(e);if(e.Button!=MouseButtons.Left)return;
        int index=CardAt(e.Location);if(index<0||String.IsNullOrEmpty(Items[index].Url))return;
        ClickedUrl=Items[index].Url;var handler=ScoreClicked;if(handler!=null)handler(this,EventArgs.Empty);
    }
    public ScoreCards(){
        SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.ResizeRedraw,true);
        AutoScroll=true;
        BackColor=Color.FromArgb(23,20,29);ForeColor=Color.White;
        DoubleBuffered=true;
        animationTimer.Interval=16;
        animationTimer.Tick+=(s,e)=>{if(animationClock.ElapsedMilliseconds>=280){animationTimer.Stop();animationKey=null;}Invalidate(new Rectangle(0,0,ClientSize.Width,RowHeight));};
        title=new Font(SessionTheme.FontName,11,FontStyle.Bold);small=new Font(SessionTheme.FontName,8);
        big=new Font(SessionTheme.FontName,18,FontStyle.Bold);rank=new Font(SessionTheme.FontName,22,FontStyle.Bold);
    }
    public void ApplyCardStyle(string font,int height,bool animations){
        if(title.FontFamily.Name!=font){title.Dispose();small.Dispose();big.Dispose();rank.Dispose();title=new Font(font,11,FontStyle.Bold);small=new Font(font,8);big=new Font(font,18,FontStyle.Bold);rank=new Font(font,22,FontStyle.Bold);}
        RowHeight=height;AnimateNewScores=animations;
        if(!animations){animationTimer.Stop();animationKey=null;}
        UpdateExtent();
    }
    public void ClearCards(){ foreach(ScoreEntry p in Items)if(p.Cover!=null)p.Cover.Dispose(); Items.Clear(); }
    public void AddCard(ScoreEntry p){
        if(!Horizontal)LoadCover(p);
        Items.Add(p);
        if(!updating){UpdateExtent();}
    }
    void LoadCover(ScoreEntry p){
        if(p.Cover!=null)return;
        if(!String.IsNullOrEmpty(p.Background)&&System.IO.File.Exists(p.Background)){
            try{
                using(var src=Image.FromFile(p.Background)){
                    int width=Math.Max(1,Width),height=104;
                    p.Cover=new Bitmap(width,height);
                    using(var g=Graphics.FromImage(p.Cover)){
                        g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                        float scale=Math.Max((float)width/src.Width,(float)height/src.Height);
                        float sw=width/scale,sh=height/scale;
                        g.DrawImage(src,new Rectangle(0,0,width,height),(src.Width-sw)/2,(src.Height-sh)/2,sw,sh,GraphicsUnit.Pixel);
                    }
                }
            }catch{}
        }
    }
    public void ReplaceCards(ScoreEntry[] next){
        var old=new Dictionary<string,ScoreEntry>();
        foreach(var item in Items)if(!String.IsNullOrEmpty(item.Key))old[item.Key]=item;
        bool added=next.Length>0&&next[0].Key!=null&&!old.ContainsKey(next[0].Key);
        foreach(var item in next){
            ScoreEntry previous;
            if(item.Key!=null&&old.TryGetValue(item.Key,out previous)&&previous.Background==item.Background){item.Cover=previous.Cover;previous.Cover=null;old.Remove(item.Key);}
            if(!Horizontal)LoadCover(item);
        }
        ClearCards();Items.AddRange(next);
        if(added&&AnimateNewScores&&Visible){animationKey=next[0].Key;animationClock.Restart();animationTimer.Start();}
        if(!updating){UpdateExtent();}
    }
    void DrawLabel(Graphics g,string s,Font f,Color c,Rectangle r,TextFormatFlags align=TextFormatFlags.Left){
        TextRenderer.DrawText(g,s??"",f,r,c,align|TextFormatFlags.EndEllipsis|TextFormatFlags.NoPadding|TextFormatFlags.SingleLine);
    }
    protected override void OnPaintBackground(PaintEventArgs e){}
    protected override void OnPaint(PaintEventArgs e){
        SessionTheme.PaintParent(this,e.Graphics);
        if(Horizontal){for(int i=TopIndex;i<Items.Count;i++){int x=i*CardWidth+AutoScrollPosition.X;if(x>ClientSize.Width)break;DrawCard(new DrawItemEventArgs(e.Graphics,Font,new Rectangle(x,0,CardWidth-12,RowHeight),i,DrawItemState.None));}return;}
        for(int i=TopIndex;i<Items.Count;i++){
            int y=i*RowHeight+AutoScrollPosition.Y;if(y>ClientSize.Height)break;
            int shift=0;
            if(animationKey!=null&&Items[i].Key==animationKey){double t=Math.Min(1,animationClock.ElapsedMilliseconds/280.0);shift=(int)(28*Math.Pow(1-t,3));}
            DrawCard(new DrawItemEventArgs(e.Graphics,Font,new Rectangle(shift,y,ClientSize.Width,RowHeight),i,DrawItemState.None));
        }
    }
    public static string[] ParseMods(string value){
        var result=new List<string>();
        foreach(Match m in Regex.Matches((value??"NM").ToUpperInvariant(),@"10K|[1-9]K|SV2|[A-Z]{2}")){
            if(!result.Contains(m.Value))result.Add(m.Value);
        }
        if(result.Contains("NC"))result.Remove("DT");if(result.Contains("DC"))result.Remove("HT");if(result.Contains("PF"))result.Remove("SD");
        return result.ToArray();
    }
    Image ModIcon(string mod){
        Image image;if(icons.TryGetValue(mod,out image))return image;
        try{string file=System.IO.Path.Combine(IconDirectory??"",mod+".png");if(System.IO.File.Exists(file))using(var src=Image.FromFile(file))image=new Bitmap(src);}catch{}
        icons[mod]=image;return image;
    }
    void DrawCard(DrawItemEventArgs e){
        if(e.Index<0)return;
        var g=e.Graphics;var p=(ScoreEntry)Items[e.Index];if(Horizontal)LoadCover(p);int x=e.Bounds.X,y=e.Bounds.Y,w=e.Bounds.Width;
        var box=new Rectangle(x,y+3,w-1,RowHeight-9);
        g.SmoothingMode=SmoothingMode.AntiAlias;
        using(var shape=SessionTheme.Rounded(box,14)){
            var saved=g.Save();g.SetClip(shape);
            using(var b=new SolidBrush(SessionTheme.CardColor))g.FillRectangle(b,box);
            if(p.Cover!=null){
                float scale=Math.Max((float)box.Width/p.Cover.Width,(float)box.Height/p.Cover.Height);float sw=box.Width/scale,sh=box.Height/scale;
                g.DrawImage(p.Cover,box,(p.Cover.Width-sw)/2,(p.Cover.Height-sh)/2,sw,sh,GraphicsUnit.Pixel);
                using(var b=new LinearGradientBrush(box,Color.FromArgb(210,23,18,31),Color.FromArgb(135,23,18,31),0f))g.FillRectangle(b,box);
            }
            using(var b=new SolidBrush(p.Fc?Color.FromArgb(126,225,186):SessionTheme.Accent))g.FillRectangle(b,x,y+3,5,RowHeight-9);
            g.Restore(saved);
        }
        if(p.Badge=="best"){using(var pen=new Pen(Color.FromArgb(155,255,211,127),1.4f))using(var path=SessionTheme.Rounded(box,14))g.DrawPath(pen,path);}
        SessionTheme.DrawScoreBadge(g,x+13,y+7,p.Badge);
        Color rc=p.Rank=="X"||p.Rank=="XH"?Color.FromArgb(255,221,127):p.Rank=="S"||p.Rank=="SH"?Color.FromArgb(255,200,105):Color.FromArgb(157,203,255);
        DrawLabel(g,p.Rank,rank,rc,new Rectangle(x+18,y+28,65,40));
        int cw=Math.Max(50,w-300);
        DrawLabel(g,p.Map,title,Color.White,new Rectangle(x+92,y+15,cw,25));
        string star=(p.Rate>0&&Math.Abs(p.Rate-1)>.001?p.Rate.ToString("0.00")+"x · ":"")+(p.Stars>0?p.Stars.ToString("0.00")+" ★  ·  ":"");
        int mx=x+92;
        var parsedMods=ParseMods(p.Mods);int modWidth=Math.Min(34,Math.Max(16,(cw-160)/Math.Max(1,parsedMods.Length)-3));
        foreach(string mod in parsedMods){
            if(mx+modWidth>x+92+cw-120)break;
            var icon=ModIcon(mod);
            if(icon!=null)g.DrawImage(icon,new Rectangle(mx,y+42,modWidth,Math.Max(12,modWidth*7/10)));
            else DrawLabel(g,mod,small,Color.White,new Rectangle(mx,y+43,modWidth,20));
            mx+=modWidth+3;
        }
        DrawLabel(g,star+p.Accuracy.ToString("0.00")+"%  ·  "+p.Combo+"x"+(p.Fc?"  ·  FC":""),small,Color.FromArgb(255,207,137),new Rectangle(mx+8,y+45,Math.Max(0,x+92+cw-mx-8),20));
        string[] judgments=(p.Hits??"").Split(new string[]{"   "},StringSplitOptions.RemoveEmptyEntries);
        Color[] hitColors={Color.FromArgb(135,210,255),Color.FromArgb(153,230,173),Color.FromArgb(255,217,136),Color.FromArgb(255,139,164)};
        int hx=x+92;
        for(int h=0;RowHeight>=110&&h<judgments.Length;h++){
            int hw=TextRenderer.MeasureText(judgments[h],small).Width+10;
            if(hx+hw>x+92+cw)break;
            DrawLabel(g,judgments[h],small,hitColors[Math.Min(h,3)],new Rectangle(hx,y+72,hw,20));hx+=hw;
        }
        if(RowHeight>=110&&hx+85<x+92+cw)DrawLabel(g,p.Time,small,Color.FromArgb(180,168,191),new Rectangle(hx+5,y+72,80,20));
        if(RowHeight<110){using(var compactPp=new Font(SessionTheme.FontName,16,FontStyle.Bold))DrawLabel(g,p.Pp.ToString("0.00")+" pp",compactPp,ControlPaint.Light(SessionTheme.Accent),new Rectangle(x+w-205,y+14,185,32),TextFormatFlags.Right);}else DrawLabel(g,p.Pp.ToString("0.00")+" pp",big,ControlPaint.Light(SessionTheme.Accent),new Rectangle(x+w-205,y+18,185,40),TextFormatFlags.Right);
        if(p.FcPp>0){
            string forecast="(if FC "+p.FcPp.ToString("0.00")+" pp)";
            using(var forecastFont=new Font(SessionTheme.FontName,8.7f,FontStyle.Bold)){
                int pw=Math.Min(190,TextRenderer.MeasureText(forecast,forecastFont).Width+18);
                var pill=new Rectangle(x+w-20-pw,y+(RowHeight>=110?64:56),pw,24);
                Color highlight=p.Fc?Color.FromArgb(151,237,200):Color.FromArgb(255,219,145);
                using(var path=SessionTheme.Rounded(pill,8)){using(var b=new SolidBrush(Color.FromArgb(46,highlight)))g.FillPath(b,path);using(var pen=new Pen(Color.FromArgb(115,highlight)))g.DrawPath(pen,path);}
                DrawLabel(g,forecast,forecastFont,highlight,pill,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter);
            }
        }
        if(animationKey!=null&&p.Key==animationKey){int alpha=(int)(180*Math.Max(0,1-animationClock.ElapsedMilliseconds/280.0));using(var pen=new Pen(Color.FromArgb(alpha,SessionTheme.Accent),2))using(var path=SessionTheme.Rounded(box,14))g.DrawPath(pen,path);}
        if((e.State&DrawItemState.Selected)!=0)using(var pen=new Pen(Color.FromArgb(239,105,164)))using(var shape=SessionTheme.Rounded(box,14))g.DrawPath(pen,shape);
    }
    protected override void Dispose(bool disposing){if(disposing){animationTimer.Stop();animationTimer.Dispose();linkTip.Dispose();ClearCards();foreach(var image in icons.Values)if(image!=null)image.Dispose();icons.Clear();title.Dispose();small.Dispose();big.Dispose();rank.Dispose();}base.Dispose(disposing);}
}
// Isolated settings preview: it never changes the application's global theme.
public class SettingsPreview : Control {
    Image wallpaper,mascot;
    string wallpaperPath;
    public Color AccentColor=Color.FromArgb(239,105,164);
    public Color PanelColor=Color.FromArgb(23,19,32);
    public int Dim=67;
    public bool ShowMascot=true,Compact,ObsMode,ShowBest=true,ShowStats=true;
    public int RecentCount=3,CardHeight=110,PanelOpacity=89,OverlayWidth=720;
    public string PreviewFont="Segoe UI",Animation="slide";
    public int AnimationSpeed=100;
    readonly System.Windows.Forms.Timer timer=new System.Windows.Forms.Timer();
    readonly System.Diagnostics.Stopwatch clock=new System.Diagnostics.Stopwatch();
    public SettingsPreview(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.ResizeRedraw,true);timer.Interval=16;timer.Tick+=(s,e)=>{if(clock.ElapsedMilliseconds>40000.0/Math.Max(25,AnimationSpeed))timer.Stop();Invalidate();};}
    public void SetWallpaper(string path){if(path==wallpaperPath)return;wallpaperPath=path;var old=wallpaper;wallpaper=null;try{if(File.Exists(path))using(var image=Image.FromFile(path))wallpaper=new Bitmap(image);}catch{}if(old!=null)old.Dispose();Invalidate();}
    public void SetMascot(string path){try{if(File.Exists(path))using(var image=Image.FromFile(path))mascot=new Bitmap(image);}catch{}}
    public void StopPreview(){timer.Stop();Invalidate();}
    public void Replay(){clock.Restart();timer.Start();Invalidate();}
    protected override void OnPaint(PaintEventArgs e){
        var g=e.Graphics;g.SmoothingMode=SmoothingMode.AntiAlias;g.Clear(Color.FromArgb(23,20,29));
        if(!ObsMode&&wallpaper!=null){float scale=Math.Max((float)Width/wallpaper.Width,(float)Height/wallpaper.Height);float sw=Width/scale,sh=Height/scale;g.DrawImage(wallpaper,ClientRectangle,(wallpaper.Width-sw)/2,(wallpaper.Height-sh)/2,sw,sh,GraphicsUnit.Pixel);using(var dim=new SolidBrush(Color.FromArgb(Dim*255/100,0,0,0)))g.FillRectangle(dim,ClientRectangle);}
        using(var title=new Font(PreviewFont,15,FontStyle.Bold))using(var body=new Font(PreviewFont,10))using(var big=new Font(PreviewFont,21,FontStyle.Bold))using(var small=new Font(PreviewFont,8))using(var accent=new SolidBrush(AccentColor)){
            if(!ObsMode){g.DrawString("osu! / session tracker 2.2",title,accent,18,18);g.DrawString("+23.35 pp     3 FC     8 plays",body,Brushes.White,18,60);DrawAnimatedPreviewCard(g,20,110,Width-40,Compact?90:110,body,big,small,accent,"slide");if(ShowMascot&&mascot!=null){int h=Math.Min(Height-250,310),w=(int)(h*(double)mascot.Width/mascot.Height);g.DrawImage(mascot,new Rectangle((Width-w)/2,240,w,h));}return;}
            // Checkerboard lets the user see the panel transparency.
            for(int y=0;y<Height;y+=20)for(int x=0;x<Width;x+=20)using(var b=new SolidBrush((x/20+y/20)%2==0?Color.FromArgb(61,60,69):Color.FromArgb(44,43,52)))g.FillRectangle(b,x,y,20,20);
            using(var panel=new SolidBrush(Color.FromArgb(PanelOpacity*255/100,PanelColor)))g.FillRectangle(panel,8,8,Width-16,Height-16);
            float previewHeight=65+(ShowStats?60:0)+(RecentCount+(ShowBest?1:0))*(CardHeight+8)+(ShowBest?22:0);float factor=Math.Min(1f,Math.Min((Width-32f)/OverlayWidth,(Height-32f)/previewHeight));var saved=g.Save();g.TranslateTransform(16,16);g.ScaleTransform(factor,factor);int yPos=0;
            g.DrawString("osu! / OBS PREVIEW",title,Brushes.White,8,yPos);yPos+=40;
            if(ShowStats){g.DrawString("+23.35 pp    3 FC    8 plays",big,accent,8,yPos);yPos+=60;}
            int count=RecentCount+(ShowBest?1:0);
            for(int i=0;i<count;i++){if(i==0&&ShowBest){g.DrawString("BEST",small,Brushes.White,8,yPos);yPos+=22;}DrawAnimatedPreviewCard(g,0,yPos,OverlayWidth-16,CardHeight,body,big,small,accent,i==0?Animation:"none");yPos+=CardHeight+8;}
            g.Restore(saved);
        }
    }
    void DrawAnimatedPreviewCard(Graphics g,int x,int y,int width,int height,Font body,Font big,Font small,Brush accent,string animation){
        double t=timer.Enabled?Math.Min(1,clock.ElapsedMilliseconds/(40000.0/Math.Max(25,AnimationSpeed))):1;
        if(animation=="rise")y+=(int)(28*Math.Pow(1-t,3));
        if(animation=="bounce")y-=(int)(Math.Sin(t*Math.PI*3)*22*(1-t));
        if(animation=="slide")x+=(int)(28*Math.Pow(1-t,3));
        if(animation=="fade"&&t<1){using(var bitmap=new Bitmap(width,height)){using(var bg=Graphics.FromImage(bitmap))DrawPreviewCard(bg,0,0,width,height,body,big,small,accent);using(var attrs=new System.Drawing.Imaging.ImageAttributes()){var matrix=new System.Drawing.Imaging.ColorMatrix();matrix.Matrix33=(float)t;attrs.SetColorMatrix(matrix);g.DrawImage(bitmap,new Rectangle(x,y,width,height),0,0,width,height,GraphicsUnit.Pixel,attrs);}}return;}
        var saved=g.Save();if(animation=="wipe"&&t<1)g.SetClip(new Rectangle(x,y,Math.Max(1,(int)(width*t)),height));if(animation=="flip"&&t<1){g.TranslateTransform(x+width/2f,0);g.ScaleTransform((float)Math.Max(.02,t),1);g.TranslateTransform(-x-width/2f,0);}
        if(animation=="pop"&&t<1){float scale=(float)(.9+.1*t);g.TranslateTransform(x+width/2f,y+height/2f);g.ScaleTransform(scale,scale);g.TranslateTransform(-x-width/2f,-y-height/2f);}
        DrawPreviewCard(g,x,y,width,height,body,big,small,accent);g.Restore(saved);
    }
    void DrawPreviewCard(Graphics g,int x,int y,int width,int height,Font body,Font big,Font small,Brush accent){
        var box=new Rectangle(x,y,width,height-5);using(var shape=SessionTheme.Rounded(box,14)){var old=g.Save();g.SetClip(shape);using(var b=new SolidBrush(Color.FromArgb(38,31,46)))g.FillRectangle(b,box);if(wallpaper!=null){g.DrawImage(wallpaper,box);using(var shade=new SolidBrush(Color.FromArgb(170,23,18,31)))g.FillRectangle(shade,box);}g.Restore(old);}
        SessionTheme.DrawScoreBadge(g,x+11,y+6,ObsMode&&ShowBest&&y<150?"best":"recent");g.FillRectangle(accent,x,y,5,height-5);g.DrawString("S",big,Brushes.Gold,x+16,y+22);g.DrawString("Demo artist - Demo map [Insane]",body,Brushes.White,x+66,y+12);g.DrawString("HD  DT   99.25% · 1250x · FC",small,Brushes.Wheat,x+66,y+42);if(height>=110)g.DrawString("300: 1000   100: 12   MISS: 0",small,Brushes.LightGray,x+66,y+68);using(var ppFont=new Font(PreviewFont,height<110?17:21,FontStyle.Bold))g.DrawString("250 pp",ppFont,accent,x+width-138,y+(height<110?14:28));var forecast=new Rectangle(x+width-138,y+(height>=110?68:54),126,22);using(var path=SessionTheme.Rounded(forecast,7))using(var brush=new SolidBrush(Color.FromArgb(50,255,219,145)))g.FillPath(brush,path);g.DrawString("(if FC 270.00 pp)",small,Brushes.Wheat,forecast.X+7,forecast.Y+4);
    }
    protected override void Dispose(bool disposing){if(disposing){timer.Dispose();if(wallpaper!=null)wallpaper.Dispose();if(mascot!=null)mascot.Dispose();}base.Dispose(disposing);}
}
public class SettingsTabs : TabControl {
    public SettingsTabs(){SizeMode=TabSizeMode.Fixed;ItemSize=new Size(1,1);Appearance=TabAppearance.FlatButtons;Padding=new Point(0,0);}
    protected override void WndProc(ref Message m){if(m.Msg==0x1328){m.Result=new IntPtr(1);return;}base.WndProc(ref m);}
}
public class SettingsSection : Panel {
    public SettingsSection(){DoubleBuffered=true;BackColor=Color.FromArgb(32,27,40);}
    protected override void OnPaintBackground(PaintEventArgs e){e.Graphics.Clear(Parent==null?Color.FromArgb(23,20,29):Parent.BackColor);e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;using(var shape=SessionTheme.Rounded(ClientRectangle,16))using(var brush=new SolidBrush(BackColor))e.Graphics.FillPath(brush,shape);}
}
public class SettingsToggle : CheckBox {
    bool hover;
    public SettingsToggle(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);Cursor=Cursors.Hand;AutoSize=false;}
    protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}
    protected override void OnMouseLeave(EventArgs e){hover=false;Invalidate();base.OnMouseLeave(e);}
    protected override void OnCheckedChanged(EventArgs e){base.OnCheckedChanged(e);Invalidate();}
    protected override void OnPaint(PaintEventArgs e){
        var g=e.Graphics;g.Clear(Parent.BackColor);g.SmoothingMode=SmoothingMode.AntiAlias;
        TextRenderer.DrawText(g,Text,Font,new Rectangle(4,0,Width-66,Height),ForeColor,TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        var rect=new Rectangle(Width-51,(Height-23)/2,45,23);using(var shape=SessionTheme.Rounded(rect,12))using(var brush=new SolidBrush(Checked?SessionTheme.Accent:hover?Color.FromArgb(92,80,106):Color.FromArgb(65,56,77)))g.FillPath(brush,shape);
        g.FillEllipse(Checked?Brushes.White:Brushes.LightGray,new Rectangle(rect.Left+(Checked?25:3),rect.Top+3,17,17));
        if(Focused)using(var pen=new Pen(Color.FromArgb(130,SessionTheme.Accent)))using(var path=SessionTheme.Rounded(new Rectangle(0,0,Width-1,Height-1),8))g.DrawPath(pen,path);
    }
}
public class SettingsCombo : Control {
    public readonly List<object> Items=new List<object>();
    int selectedIndex=-1;bool hover;
    readonly ContextMenuStrip choiceMenu=new ContextMenuStrip();
    public ComboBoxStyle DropDownStyle{get;set;}
    public event EventHandler SelectedIndexChanged;
    public int SelectedIndex{get{return selectedIndex;}set{int next=value>=0&&value<Items.Count?value:-1;if(selectedIndex==next)return;selectedIndex=next;Invalidate();var handler=SelectedIndexChanged;if(handler!=null)handler(this,EventArgs.Empty);}}
    public object SelectedItem{get{return selectedIndex>=0?Items[selectedIndex]:null;}set{SelectedIndex=Items.IndexOf(value);}}
    public SettingsCombo(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.Selectable,true);BackColor=Color.FromArgb(48,40,59);ForeColor=Color.FromArgb(242,233,249);Cursor=Cursors.Hand;TabStop=true;AccessibleRole=AccessibleRole.ComboBox;}
    protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}
    protected override void OnMouseLeave(EventArgs e){hover=false;Invalidate();base.OnMouseLeave(e);}
    protected override void OnGotFocus(EventArgs e){Invalidate();base.OnGotFocus(e);}
    protected override void OnLostFocus(EventArgs e){Invalidate();base.OnLostFocus(e);}
    protected override void OnMouseClick(MouseEventArgs e){base.OnMouseClick(e);if(e.Button==MouseButtons.Left){Focus();OpenMenu();}}
    protected override bool IsInputKey(Keys key){return key==Keys.Up||key==Keys.Down||base.IsInputKey(key);}
    protected override void OnKeyDown(KeyEventArgs e){base.OnKeyDown(e);if(e.KeyCode==Keys.Down){SelectedIndex=Math.Min(Items.Count-1,selectedIndex+1);e.Handled=true;}else if(e.KeyCode==Keys.Up){SelectedIndex=Math.Max(0,selectedIndex-1);e.Handled=true;}else if(e.KeyCode==Keys.Space||e.KeyCode==Keys.Enter){OpenMenu();e.Handled=true;}}
    void OpenMenu(){
        if(IsDisposed||Disposing||!IsHandleCreated||choiceMenu.Visible)return;
        // Keep the dropdown alive until its owner is disposed. WinForms still
        // uses it after Closed while removing its modal message filter.
        var menu=choiceMenu;
        while(menu.Items.Count>0){var old=menu.Items[0];menu.Items.RemoveAt(0);old.Dispose();}
        menu.ShowImageMargin=false;menu.BackColor=BackColor;menu.ForeColor=ForeColor;menu.Renderer=new SettingsMenuRenderer();
        for(int i=0;i<Items.Count;i++){int index=i;var item=new ToolStripMenuItem((i==selectedIndex?"✓  ":"    ")+Convert.ToString(Items[i]));item.BackColor=BackColor;item.ForeColor=ForeColor;item.Font=Font;item.AutoSize=false;item.Size=new Size(Math.Max(100,Width-6),32);item.Click+=(s,e)=>SelectedIndex=index;menu.Items.Add(item);}
        menu.Show(this,new Point(0,Height+3));
    }
    protected override void Dispose(bool disposing){if(disposing){choiceMenu.Close();choiceMenu.Dispose();}base.Dispose(disposing);}
    protected override void OnPaint(PaintEventArgs e){
        var g=e.Graphics;g.Clear(Parent.BackColor);g.SmoothingMode=SmoothingMode.AntiAlias;
        using(var shape=SessionTheme.Rounded(new Rectangle(0,0,Width-1,Height-1),10)){using(var brush=new SolidBrush(hover?Color.FromArgb(57,46,69):BackColor))g.FillPath(brush,shape);using(var pen=new Pen(Focused?SessionTheme.Accent:Color.FromArgb(77,64,91)))g.DrawPath(pen,shape);}
        TextRenderer.DrawText(g,Convert.ToString(SelectedItem),Font,new Rectangle(12,0,Width-48,Height),ForeColor,TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        using(var pen=new Pen(Color.FromArgb(193,177,208),1.8f)){int x=Width-20,y=Height/2;g.DrawLines(pen,new Point[]{new Point(x-4,y-2),new Point(x,y+2),new Point(x+4,y-2)});}
    }
}
public class SettingsMenuRenderer : ToolStripProfessionalRenderer {
    protected override void OnRenderMenuItemBackground(ToolStripItemRenderEventArgs e){using(var brush=new SolidBrush(e.Item.Selected?Color.FromArgb(78,52,86):Color.FromArgb(48,40,59)))e.Graphics.FillRectangle(brush,new Rectangle(Point.Empty,e.Item.Size));}
    protected override void OnRenderToolStripBorder(ToolStripRenderEventArgs e){using(var pen=new Pen(Color.FromArgb(91,72,104)))e.Graphics.DrawRectangle(pen,0,0,e.ToolStrip.Width-1,e.ToolStrip.Height-1);}
}
public class SettingsNumber : UserControl {
    decimal value,minimum,maximum=100,increment=1;
    readonly TextBox field=new TextBox();readonly SessionButton minus=new SessionButton(),plus=new SessionButton();bool updating;
    public event EventHandler ValueChanged;
    public decimal Minimum{get{return minimum;}set{minimum=value;if(maximum<minimum)maximum=minimum;Value=this.value;}}
    public decimal Maximum{get{return maximum;}set{maximum=value;if(minimum>maximum)minimum=maximum;Value=this.value;}}
    public decimal Increment{get{return increment;}set{increment=value;}}
    public decimal Value{get{return value;}set{decimal next=Math.Max(minimum,Math.Min(maximum,value));bool changed=next!=this.value;this.value=next;updating=true;field.Text=next.ToString("0");updating=false;if(changed){var handler=ValueChanged;if(handler!=null)handler(this,EventArgs.Empty);}Invalidate();}}
    public SettingsNumber(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);BackColor=Color.FromArgb(48,40,59);field.BorderStyle=BorderStyle.None;field.BackColor=BackColor;field.ForeColor=Color.White;field.TextAlign=HorizontalAlignment.Center;field.Text="0";minus.Text="−";plus.Text="+";Controls.Add(field);Controls.Add(minus);Controls.Add(plus);minus.Click+=(s,e)=>Value-=increment;plus.Click+=(s,e)=>Value+=increment;field.Leave+=(s,e)=>Commit();field.KeyDown+=(s,e)=>{if(e.KeyCode==Keys.Enter){Commit();e.SuppressKeyPress=true;}else if(e.KeyCode==Keys.Up){Value+=increment;e.SuppressKeyPress=true;}else if(e.KeyCode==Keys.Down){Value-=increment;e.SuppressKeyPress=true;}};Resize+=(s,e)=>LayoutFields();FontChanged+=(s,e)=>LayoutFields();}
    void Commit(){if(updating)return;decimal number;if(decimal.TryParse(field.Text,out number))Value=number;else Value=value;}
    void LayoutFields(){minus.SetBounds(2,1,29,Math.Max(25,Height-2));plus.SetBounds(Width-31,1,29,Math.Max(25,Height-2));field.Font=Font;field.SetBounds(33,Math.Max(3,(Height-field.PreferredHeight)/2),Math.Max(15,Width-66),field.PreferredHeight);}
    protected override void OnPaint(PaintEventArgs e){e.Graphics.Clear(Parent.BackColor);e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;using(var path=SessionTheme.Rounded(ClientRectangle,9))using(var brush=new SolidBrush(BackColor))e.Graphics.FillPath(brush,path);}
}
public class SessionStats : Control {
    string[] values=new string[]{"—","0","0","00:00:00","0.00 pp"};
    public bool English,Finished;
    public void SetValues(string gain,int fcs,int passed,string duration,string total,bool english,bool finished){values=new string[]{gain,fcs.ToString(),passed.ToString(),duration,total};English=english;Finished=finished;AccessibleName=english?"Session statistics":"Статистика сессии";Invalidate();}
    public SessionStats(){SetStyle(ControlStyles.SupportsTransparentBackColor|ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.ResizeRedraw,true);BackColor=Color.Transparent;}
    protected override void OnPaintBackground(PaintEventArgs e){SessionTheme.PaintParent(this,e.Graphics);}
    protected override void OnPaint(PaintEventArgs e){
        var g=e.Graphics;g.SmoothingMode=SmoothingMode.AntiAlias;
        string[] labels=English?new string[]{"Profile pp gain","FC · Full combos","Maps passed","Session time","Total play pp"}:new string[]{"Прирост pp","FC · Полные комбо","Пройдено карт","Время сессии","Сумма pp карт"};
        string[] hints=English?new string[]{"Actual profile change","FULL COMBO","Completed plays",Finished?"Session finished":"Current session","Calculated map pp"}:new string[]{"Реальный прирост","FULL COMBO","Успешные прохождения",Finished?"Сессия завершена":"Текущая сессия","Расчётные pp карт"};
        Color[] colors=new Color[]{SessionTheme.Accent,Color.FromArgb(126,225,186),Color.FromArgb(126,204,255),Color.FromArgb(191,165,244),Color.FromArgb(255,211,127)};
        int gap=10,pad=2,w=(ClientSize.Width-pad*2-gap*4)/5,h=ClientSize.Height-8;
        using(var labelFont=new Font(SessionTheme.FontName,9,FontStyle.Bold))using(var hintFont=new Font(SessionTheme.FontName,7.4f)){
            for(int i=0;i<5;i++){
                int x=pad+i*(w+gap),y=3;var rect=new Rectangle(x,y,w,h);
                using(var path=SessionTheme.Rounded(rect,17)){using(var bg=new SolidBrush(Color.FromArgb(245,SessionTheme.PanelColor)))g.FillPath(bg,path);using(var pen=new Pen(Color.FromArgb(65,colors[i])))g.DrawPath(pen,path);}
                using(var glow=new SolidBrush(Color.FromArgb(32,colors[i])))g.FillEllipse(glow,x+13,y+13,30,30);
                DrawIcon(g,x+20,y+20,i,colors[i]);
                TextRenderer.DrawText(g,labels[i],labelFont,new Rectangle(x+50,y+16,w-58,25),Color.FromArgb(225,215,235),TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis|TextFormatFlags.NoPadding);
                float size=22;Font number=new Font(SessionTheme.FontName,size,FontStyle.Bold);
                while(TextRenderer.MeasureText(values[i],number).Width>w-28&&size>12){number.Dispose();size--;number=new Font(SessionTheme.FontName,size,FontStyle.Bold);}
                using(number)TextRenderer.DrawText(g,values[i],number,new Rectangle(x+15,y+48,w-27,40),colors[i],TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis|TextFormatFlags.NoPadding);
                TextRenderer.DrawText(g,hints[i],hintFont,new Rectangle(x+15,y+h-28,w-27,20),Color.FromArgb(171,158,187),TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis|TextFormatFlags.NoPadding);
            }
        }
    }
    static void DrawIcon(Graphics g,int x,int y,int kind,Color color){
        using(var pen=new Pen(color,1.8f))using(var brush=new SolidBrush(color)){
            if(kind==0){g.DrawLines(pen,new Point[]{new Point(x,y+12),new Point(x+5,y+7),new Point(x+9,y+10),new Point(x+15,y+2)});g.DrawLines(pen,new Point[]{new Point(x+10,y+2),new Point(x+15,y+2),new Point(x+15,y+7)});}
            else if(kind==1){g.DrawEllipse(pen,x+2,y,12,12);g.DrawLines(pen,new Point[]{new Point(x+3,y+11),new Point(x+1,y+17),new Point(x+7,y+14),new Point(x+9,y+17),new Point(x+13,y+11)});var points=new PointF[10];for(int j=0;j<10;j++){double a=-Math.PI/2+j*Math.PI/5;double r=j%2==0?4:1.8;points[j]=new PointF(x+8+(float)(Math.Cos(a)*r),y+6+(float)(Math.Sin(a)*r));}g.FillPolygon(brush,points);}
            else if(kind==2){g.DrawRectangle(pen,x+1,y+1,14,14);g.DrawLines(pen,new Point[]{new Point(x+4,y+8),new Point(x+7,y+11),new Point(x+13,y+5)});}
            else if(kind==3){g.DrawEllipse(pen,x,y,16,16);g.DrawLines(pen,new Point[]{new Point(x+8,y+3),new Point(x+8,y+8),new Point(x+12,y+10)});}
            else{g.DrawEllipse(pen,x,y,16,16);g.DrawLine(pen,x+4,y+8,x+12,y+8);g.DrawLine(pen,x+8,y+4,x+8,y+12);}
        }
    }
}

public class SessionRecap : Control {
    Image wallpaper;readonly ScoreCards best=new ScoreCards();
    public string Player="osu! player",DateText="",Gain="—",Duration="00:00:00",Total="0 pp",Client="stable";
    public int FcCount,PlayCount,Dim=65;public bool English=true,HasBest;
    public SessionRecap(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);Size=new Size(1000,720);BackColor=Color.FromArgb(24,20,32);best.SetBounds(45,493,910,157);best.ApplyCardStyle(SessionTheme.FontName,150,false);Controls.Add(best);}
    public void SetWallpaper(string path){var old=wallpaper;wallpaper=null;try{if(File.Exists(path))using(var img=Image.FromFile(path))wallpaper=new Bitmap(img);}catch{}if(old!=null)old.Dispose();Invalidate();}
    public void SetBest(ScoreEntry entry){HasBest=entry!=null;best.Visible=HasBest;if(HasBest)best.ReplaceCards(new ScoreEntry[]{entry});else best.ClearCards();Invalidate();}
    public Bitmap RenderImage(){var bitmap=new Bitmap(1000,720);DrawToBitmap(bitmap,new Rectangle(0,0,1000,720));return bitmap;}
    void DrawLabel(Graphics g,string value,float size,Color color,Rectangle area,bool bold){using(var f=new Font(SessionTheme.FontName,size,bold?FontStyle.Bold:FontStyle.Regular))TextRenderer.DrawText(g,value,f,area,color,TextFormatFlags.NoPadding|TextFormatFlags.EndEllipsis|TextFormatFlags.VerticalCenter);}
    protected override void OnPaint(PaintEventArgs e){var g=e.Graphics;g.SmoothingMode=SmoothingMode.AntiAlias;g.Clear(Color.FromArgb(24,20,32));
        if(wallpaper!=null){float ratio=Math.Max(1000f/wallpaper.Width,720f/wallpaper.Height);float sw=1000/ratio,sh=720/ratio;g.DrawImage(wallpaper,new Rectangle(0,0,1000,720),(wallpaper.Width-sw)/2,(wallpaper.Height-sh)/2,sw,sh,GraphicsUnit.Pixel);}
        using(var dim=new SolidBrush(Color.FromArgb(Math.Max(0,Math.Min(90,Dim))*255/100,13,10,21)))g.FillRectangle(dim,ClientRectangle);
        using(var shade=new LinearGradientBrush(ClientRectangle,Color.FromArgb(15,20,16,28),Color.FromArgb(235,20,16,28),90))g.FillRectangle(shade,ClientRectangle);
        DrawLabel(g,"osu! / SESSION TRACKER",12,Color.FromArgb(224,205,235),new Rectangle(45,28,600,30),true);
        DrawLabel(g,Client=="lazer"?"osu!lazer":"osu!stable",12,Color.FromArgb(224,205,235),new Rectangle(815,28,140,30),true);
        DrawLabel(g,Player,26,Color.White,new Rectangle(45,100,910,55),true);DrawLabel(g,DateText,12,Color.FromArgb(209,196,221),new Rectangle(45,157,910,30),false);
        DrawLabel(g,English?"PROFILE PP GAINED":"ПРИРОСТ PP ПРОФИЛЯ",12,Color.FromArgb(216,198,228),new Rectangle(45,219,900,28),true);
        DrawLabel(g,Gain+" pp",51,SessionTheme.Accent,new Rectangle(42,250,910,95),true);
        string[] values={"✦ "+FcCount,PlayCount.ToString(),Duration,Total};string[] labels=English?new[]{"FULL COMBOS","MAPS PASSED","SESSION TIME","TOTAL PLAY PP"}:new[]{"ПОЛНЫЕ КОМБО","ПРОЙДЕНО КАРТ","ВРЕМЯ СЕССИИ","СУММА PP КАРТ"};
        for(int i=0;i<4;i++){int x=45+i*232;using(var path=SessionTheme.Rounded(new Rectangle(x,363,214,89),15))using(var brush=new SolidBrush(Color.FromArgb(210,SessionTheme.PanelColor)))g.FillPath(brush,path);DrawLabel(g,values[i],21,Color.White,new Rectangle(x+13,373,190,38),true);DrawLabel(g,labels[i],9,Color.FromArgb(204,188,218),new Rectangle(x+13,417,190,23),false);}
        DrawLabel(g,English?"★ BEST PLAY THIS SESSION":"★ ЛУЧШИЙ СКОР СЕССИИ",11,Color.FromArgb(255,214,142),new Rectangle(45,462,900,25),true);
        if(!HasBest)DrawLabel(g,English?"No scores recorded yet":"В этой сессии пока нет скоров",17,Color.LightGray,new Rectangle(45,525,910,80),false);
        DrawLabel(g,"osu! session tracker · 2.2",10,Color.FromArgb(178,163,193),new Rectangle(45,674,600,22),false);
        DrawLabel(g,English?"Calculated play pp ≠ profile pp gain":"Расчётные pp карт ≠ прирост pp профиля",10,Color.FromArgb(178,163,193),new Rectangle(495,674,460,22),false);
    }
    protected override void Dispose(bool disposing){if(disposing&&wallpaper!=null)wallpaper.Dispose();base.Dispose(disposing);}
}

public class HistorySessionList : ListBox {
    public HistorySessionList(){DrawMode=DrawMode.OwnerDrawFixed;ItemHeight=52;SetStyle(ControlStyles.OptimizedDoubleBuffer,true);}
    protected override void OnDrawItem(DrawItemEventArgs e){if(e.Index<0)return;var g=e.Graphics;g.SmoothingMode=SmoothingMode.AntiAlias;using(var b=new SolidBrush(BackColor))g.FillRectangle(b,e.Bounds);bool selected=(e.State&DrawItemState.Selected)!=0;
        var rect=new Rectangle(e.Bounds.X+3,e.Bounds.Y+3,e.Bounds.Width-7,e.Bounds.Height-6);if(selected)using(var p=SessionTheme.Rounded(rect,9))using(var b=new SolidBrush(Color.FromArgb(70,SessionTheme.Accent)))g.FillPath(b,p);
        using(var f=new Font("Segoe UI",11,FontStyle.Bold))TextRenderer.DrawText(g,GetItemText(Items[e.Index]),f,new Rectangle(rect.X+12,rect.Y,rect.Width-20,rect.Height),selected?Color.White:Color.FromArgb(206,190,222),TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
    }
}

public class ArchiveLayoutPreview : Control {
    public bool Vertical;
    public ArchiveLayoutPreview(){DoubleBuffered=true;}
    protected override void OnPaint(PaintEventArgs e){e.Graphics.Clear(Parent.BackColor);e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;for(int i=0;i<3;i++){var box=Vertical?new Rectangle(2,i*13,Width-5,10):new Rectangle(i*(Width/3)+2,3,Width/3-8,32);using(var shape=SessionTheme.Rounded(box,4))using(var brush=new SolidBrush(Color.FromArgb(55,SessionTheme.Accent)))e.Graphics.FillPath(brush,shape);using(var brush=new SolidBrush(SessionTheme.Accent))e.Graphics.FillRectangle(brush,box.X+6,box.Y+3,Math.Max(12,box.Width/3),3);}}
}
