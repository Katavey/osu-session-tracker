using System;
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
    public string Map,Mods,Rank,Time,Hits,Background,Url,Key;
    public double Pp,Accuracy,Stars,FcPp;
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
    public bool AnimateNewScores=true;
    readonly System.Windows.Forms.Timer animationTimer=new System.Windows.Forms.Timer();
    readonly System.Diagnostics.Stopwatch animationClock=new System.Diagnostics.Stopwatch();
    string animationKey;
    ToolTip linkTip=new ToolTip();
    string tipText;
    public event EventHandler ScoreClicked;
    public string ClickedUrl {get;private set;}
    public int TopIndex {get{return Math.Max(0,-AutoScrollPosition.Y/RowHeight);}set{AutoScrollPosition=new Point(0,Math.Max(0,value)*RowHeight);}}
    public void BeginUpdate(){updating=true;}
    public void EndUpdate(){updating=false;AutoScrollMinSize=new Size(0,Items.Count*RowHeight);Invalidate();}
    public int CardAt(Point point){
        if(point.X<0||point.X>=ClientSize.Width||point.Y<0||point.Y>=ClientSize.Height)return -1;
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
        AutoScrollMinSize=new Size(0,Items.Count*RowHeight);Invalidate();
    }
    public void ClearCards(){ foreach(ScoreEntry p in Items)if(p.Cover!=null)p.Cover.Dispose(); Items.Clear(); }
    public void AddCard(ScoreEntry p){
        LoadCover(p);
        Items.Add(p);
        if(!updating){AutoScrollMinSize=new Size(0,Items.Count*RowHeight);Invalidate();}
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
            LoadCover(item);
        }
        ClearCards();Items.AddRange(next);
        if(added&&AnimateNewScores&&Visible){animationKey=next[0].Key;animationClock.Restart();animationTimer.Start();}
        if(!updating){AutoScrollMinSize=new Size(0,Items.Count*RowHeight);Invalidate();}
    }
    void DrawLabel(Graphics g,string s,Font f,Color c,Rectangle r,TextFormatFlags align=TextFormatFlags.Left){
        TextRenderer.DrawText(g,s??"",f,r,c,align|TextFormatFlags.EndEllipsis|TextFormatFlags.NoPadding|TextFormatFlags.SingleLine);
    }
    protected override void OnPaintBackground(PaintEventArgs e){}
    protected override void OnPaint(PaintEventArgs e){
        SessionTheme.PaintParent(this,e.Graphics);
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
        if(result.Contains("NC"))result.Remove("DT");if(result.Contains("PF"))result.Remove("SD");
        return result.ToArray();
    }
    Image ModIcon(string mod){
        Image image;if(icons.TryGetValue(mod,out image))return image;
        try{string file=System.IO.Path.Combine(IconDirectory??"",mod+".png");if(System.IO.File.Exists(file))using(var src=Image.FromFile(file))image=new Bitmap(src);}catch{}
        icons[mod]=image;return image;
    }
    void DrawCard(DrawItemEventArgs e){
        if(e.Index<0)return;
        var g=e.Graphics;var p=(ScoreEntry)Items[e.Index];int x=e.Bounds.X,y=e.Bounds.Y,w=e.Bounds.Width;
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
        Color rc=p.Rank=="X"||p.Rank=="XH"?Color.FromArgb(255,221,127):p.Rank=="S"||p.Rank=="SH"?Color.FromArgb(255,200,105):Color.FromArgb(157,203,255);
        DrawLabel(g,p.Rank,rank,rc,new Rectangle(x+18,y+28,65,40));
        int cw=Math.Max(50,w-300);
        DrawLabel(g,p.Map,title,Color.White,new Rectangle(x+92,y+15,cw,25));
        string star=p.Stars>0?p.Stars.ToString("0.00")+" ★  ·  ":"";
        int mx=x+92;
        foreach(string mod in ParseMods(p.Mods)){
            if(mx+36>x+92+cw/2)break;
            var icon=ModIcon(mod);
            if(icon!=null)g.DrawImage(icon,new Rectangle(mx,y+40,34,24));
            else DrawLabel(g,mod,small,Color.White,new Rectangle(mx,y+43,34,20));
            mx+=37;
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
        DrawLabel(g,p.Pp.ToString("0.00")+" pp",big,ControlPaint.Light(SessionTheme.Accent),new Rectangle(x+w-205,y+18,185,40),TextFormatFlags.Right);
        DrawLabel(g,p.FcPp>0?"if FC  "+p.FcPp.ToString("0.00")+" pp":"",small,Color.FromArgb(193,175,204),new Rectangle(x+w-205,y+(RowHeight>=110?64:56),185,25),TextFormatFlags.Right);
        if(animationKey!=null&&p.Key==animationKey){int alpha=(int)(180*Math.Max(0,1-animationClock.ElapsedMilliseconds/280.0));using(var pen=new Pen(Color.FromArgb(alpha,SessionTheme.Accent),2))using(var path=SessionTheme.Rounded(box,14))g.DrawPath(pen,path);}
        if((e.State&DrawItemState.Selected)!=0)using(var pen=new Pen(Color.FromArgb(239,105,164)))using(var shape=SessionTheme.Rounded(box,14))g.DrawPath(pen,shape);
    }
    protected override void Dispose(bool disposing){if(disposing){animationTimer.Stop();animationTimer.Dispose();linkTip.Dispose();ClearCards();foreach(var image in icons.Values)if(image!=null)image.Dispose();icons.Clear();title.Dispose();small.Dispose();big.Dispose();rank.Dispose();}base.Dispose(disposing);}
}
