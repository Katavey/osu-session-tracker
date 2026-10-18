using System;
using System.IO;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

public sealed class ObsOverlay : IDisposable {
    TcpListener listener;
    CancellationTokenSource cancel;
    Task worker;
    readonly SemaphoreSlim slots=new SemaphoreSlim(8);
    string state="{}",html;
    readonly Dictionary<string,string> images=new Dictionary<string,string>();
    readonly Dictionary<string,string> imagePaths=new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase);
    public string RegisterImage(string path){
        if(String.IsNullOrEmpty(path)||!File.Exists(path))return "";
        string ext=Path.GetExtension(path).ToLowerInvariant();
        // Lazer realm assets use hash names with no image extension.
        if(ext!=""&&ext!=".png"&&ext!=".jpg"&&ext!=".jpeg"&&ext!=".bmp")return "";
        lock(images){
            string url;if(imagePaths.TryGetValue(path,out url))return url;
            if(images.Count>=256){images.Clear();imagePaths.Clear();}
            url="/image/"+Guid.NewGuid().ToString("N");images[url]=path;imagePaths[path]=url;return url;
        }
    }
    public int Port {get;private set;}
    public string Url {get{return "http://127.0.0.1:"+Port+"/";}}
    public string TikTokUrl {get{return "http://127.0.0.1.nip.io:"+Port;}}
    public void SetState(string json){Interlocked.Exchange(ref state,json);}
    public void Start(string page){Start(page,24051,24059);}
    public void StartPreview(string page){Start(page,24151,24159);}
    void Start(string page,int firstPort,int lastPort){
        if(listener!=null)return;
        html=File.ReadAllText(page);
        for(int port=firstPort;port<=lastPort;port++){
            var attempt=new TcpListener(IPAddress.Loopback,port);
            try{attempt.Start(16);listener=attempt;Port=port;break;}catch(SocketException){attempt.Stop();}
        }
        if(listener==null)throw new IOException("Overlay ports "+firstPort+"-"+lastPort+" are busy.");
        cancel=new CancellationTokenSource();worker=Task.Run(()=>AcceptLoop(cancel.Token));
    }
    async Task AcceptLoop(CancellationToken token){
        while(!token.IsCancellationRequested){
            try{
                var client=await listener.AcceptTcpClientAsync().ConfigureAwait(false);
                if(!slots.Wait(0)){client.Close();continue;}
                Handle(client,token);
            }catch(ObjectDisposedException){break;}catch(SocketException){if(token.IsCancellationRequested)break;}
        }
    }
    async void Handle(TcpClient client,CancellationToken token){
        try{using(client)using(var timeout=CancellationTokenSource.CreateLinkedTokenSource(token)){
            timeout.CancelAfter(3000);
            var stream=client.GetStream();var buffer=new byte[8192];int count=0;
            while(count<buffer.Length){int n=await stream.ReadAsync(buffer,count,buffer.Length-count,timeout.Token).ConfigureAwait(false);if(n==0)return;count+=n;if(Encoding.ASCII.GetString(buffer,0,count).Contains("\r\n\r\n"))break;}
            string request=Encoding.ASCII.GetString(buffer,0,count).Split('\n')[0];string[] parts=request.Trim().Split(' ');
            string code="200 OK",type="text/html; charset=utf-8",body="";byte[] bytes=null;bool asset=false;
            if(parts.Length<2||parts[0]!="GET"){code="405 Method Not Allowed";body="GET required";}
            else if(parts[1]=="/tiktok"||parts[1]=="/tiktok/"){body=TikTokRenderer.Page(state);}
            else if(parts[1]=="/tiktok/content"){body=TikTokRenderer.Content(state);}
            else if(parts[1]=="/diagnostic"){body="<!doctype html><html><body style=\"background:#172c28;color:#fff;font:32px Arial;padding:30px\">Tracker connection OK / Подключение работает</body></html>";}
            else if(parts[1]=="/state"){type="application/json; charset=utf-8";body=state;}
            else if(parts[1]=="/"||parts[1]=="/index.html"){body=html;}
            else if(parts[1].StartsWith("/image/",StringComparison.Ordinal)){
                string path;lock(images){images.TryGetValue(parts[1],out path);}
                if(path!=null&&File.Exists(path)&&new FileInfo(path).Length<=26214400){
                    bytes=File.ReadAllBytes(path);asset=true;
                    if(bytes.Length>=8&&bytes[0]==137&&bytes[1]==80&&bytes[2]==78&&bytes[3]==71)type="image/png";
                    else if(bytes.Length>=3&&bytes[0]==255&&bytes[1]==216&&bytes[2]==255)type="image/jpeg";
                    else if(bytes.Length>=2&&bytes[0]==66&&bytes[1]==77)type="image/bmp";
                    else{bytes=null;asset=false;code="404 Not Found";body="Not an image";}
                }else{code="404 Not Found";body="Not found";}
            }
            else{code="404 Not Found";body="Not found";}
            if(bytes==null)bytes=Encoding.UTF8.GetBytes(body);
            byte[] header=Encoding.ASCII.GetBytes("HTTP/1.1 "+code+"\r\nContent-Type: "+type+"\r\nContent-Length: "+bytes.Length+"\r\nCache-Control: "+(asset?"private, max-age=3600":"no-store")+"\r\nConnection: close\r\nX-Content-Type-Options: nosniff\r\n\r\n");
            await stream.WriteAsync(header,0,header.Length,timeout.Token).ConfigureAwait(false);
            await stream.WriteAsync(bytes,0,bytes.Length,timeout.Token).ConfigureAwait(false);
        }}catch(Exception){}finally{slots.Release();}
    }
    public void Dispose(){
        if(cancel==null)return;
        cancel.Cancel();listener.Stop();try{worker.Wait(1000);}catch{}
        listener=null;cancel.Dispose();cancel=null;Port=0;
    }
}

public static class TikTokRenderer {
    static string S(System.Collections.Generic.IDictionary<string,object> d,string k){object v;return d!=null&&d.TryGetValue(k,out v)&&v!=null?System.Convert.ToString(v,System.Globalization.CultureInfo.InvariantCulture):"";}
    static double N(System.Collections.Generic.IDictionary<string,object> d,string k){double n;return double.TryParse(S(d,k),System.Globalization.NumberStyles.Float,System.Globalization.CultureInfo.InvariantCulture,out n)?n:0;}
    static bool On(System.Collections.Generic.IDictionary<string,object> d,string k){return S(d,k)!="False"&&S(d,k)!="false";}
    static string E(string s){return System.Net.WebUtility.HtmlEncode(s??"");}
    static string P(double n){return n.ToString("0.00",System.Globalization.CultureInfo.InvariantCulture);}
    static string ImagePath(string s){return System.Text.RegularExpressions.Regex.IsMatch(s??"",@"^/image/[a-f0-9]{32}$")?s:"";}
    static string Score(object value,bool ru,string category){
        var p=value as System.Collections.Generic.IDictionary<string,object>;if(p==null)return "<div class='empty'>"+(ru?"Нет подходящего скора":"No eligible score")+"</div>";
        var b=new System.Text.StringBuilder();b.Append("<div class='score'><div class='category'>").Append(category).Append("</div><table class='scoretable'><tr><td class='rank'>").Append(E(S(p,"rank"))).Append("</td><td class='mapcell'><div class='map'>").Append(E(S(p,"map"))).Append("</div><div class='mods'>");
        var mods=p.ContainsKey("mods")?p["mods"] as System.Collections.IEnumerable:null;
        if(mods!=null)foreach(var valueMod in mods){var mod=valueMod as System.Collections.Generic.IDictionary<string,object>;string image=ImagePath(S(mod,"image"));if(image!="")b.Append("<img class='mod' src='").Append(image).Append("' alt='").Append(E(S(mod,"name"))).Append("'>");else b.Append(E(S(mod,"name"))).Append(" ");}
        b.Append("</div><div class='meta'>").Append(P(N(p,"accuracy"))).Append("% · ").Append(E(S(p,"combo"))).Append("×");if(On(p,"fc"))b.Append(" · FC");if(N(p,"rate")>0&&System.Math.Abs(N(p,"rate")-1)>.001)b.Append(" · ").Append(P(N(p,"rate"))).Append("×");
        b.Append("</div></td><td class='points'>").Append(P(N(p,"pp"))).Append("<small> pp</small>");if(N(p,"fcPp")>0)b.Append("<div class='forecast'>(if FC ").Append(P(N(p,"fcPp"))).Append(" pp)</div>");b.Append("</td></tr></table>");
        string bg=ImagePath(S(p,"background"));if(bg!="")b.Append("<img class='background' src='").Append(bg).Append("' alt=''>");return b.Append("</div>").ToString();
    }
    public static string Content(string json){
        var serializer=new System.Web.Script.Serialization.JavaScriptSerializer();serializer.MaxJsonLength=2097152;
        var s=serializer.DeserializeObject(json) as System.Collections.Generic.IDictionary<string,object>;
        if(s==null)s=new System.Collections.Generic.Dictionary<string,object>();bool ru=S(s,"language")=="ru";
        string accent=S(s,"accent");if(!System.Text.RegularExpressions.Regex.IsMatch(accent,@"^#[a-fA-F0-9]{6}$"))accent="#ef69a4";
        int width=(int)System.Math.Max(600,System.Math.Min(1200,N(s,"width")>0?N(s,"width"):720));
        var b=new System.Text.StringBuilder();b.Append("<div id='tt-style'><style>.panel{width:").Append(width).Append("px}.gain,.points{color:").Append(accent).Append("}</style></div>");
        long sec=(long)System.Math.Max(0,N(s,"seconds"));b.Append("<div id='tt-head'><table class='header'><tr><td>osu! / SESSION TRACKER</td><td class='right'>").Append((sec/3600).ToString("00")).Append(":").Append((sec/60%60).ToString("00")).Append(":").Append((sec%60).ToString("00")).Append("</td></tr></table></div>");
        b.Append("<div id='tt-stats'>");if(On(s,"showStats")){b.Append("<table class='stats'><tr><td><strong class='gain'>").Append(S(s,"gain")==""?"—":(N(s,"gain")>0?"+":"")+P(N(s,"gain"))).Append("</strong><br>").Append(ru?"PP ПРОФИЛЯ":"PROFILE PP").Append("</td><td><strong>").Append(E(S(s,"fc"))).Append("</strong><br>FC</td><td><strong>").Append(E(S(s,"plays"))).Append("</strong><br>").Append(ru?"КАРТЫ":"PLAYS").Append("</td></tr></table>");}b.Append("</div><div id='tt-best'>");
        if(On(s,"showBest")){b.Append("<h2>").Append(ru?"ЛУЧШИЙ СКОР":"SESSION BEST").Append("</h2>");object best;s.TryGetValue("best",out best);b.Append(Score(best,ru,"BEST"));}b.Append("</div><div id='tt-recent'>");
        if(On(s,"showRecent")){b.Append("<h2>").Append(ru?"ПОСЛЕДНИЕ СКОРЫ":"RECENT SCORES").Append("</h2>");object recent;int count=0;if(s.TryGetValue("recent",out recent)&&recent is System.Collections.IEnumerable)foreach(var p in (System.Collections.IEnumerable)recent){if(count++>=5)break;b.Append(Score(p,ru,"RECENT"));}if(count==0)b.Append("<div class='empty'>").Append(ru?"Ожидание скора…":"Waiting for a score…").Append("</div>");}b.Append("</div><div id='tt-note'>");if(On(s,"ended")&&S(s,"ended")!="")b.Append(ru?"Сессия завершена":"Session finished");return b.Append("</div>").ToString();
    }
    public static string Page(string json){
        return "<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>osu! tracker · TikTok compatibility</title><style>"+
        "*{box-sizing:border-box}html,body{margin:0;padding:0;background:#17131f;color:#fff;font:16px 'Segoe UI',Arial,sans-serif}.panel{padding:18px;background:#17131f}.header{width:100%;font-size:13px;font-weight:bold;letter-spacing:1px}.right{text-align:right}.stats{width:100%;margin:18px 0;font-size:11px;color:#cabbda}.stats td{width:33%}.stats strong{font-size:27px;color:#f4aad2}.stats .gain{color:inherit}h2{font-size:11px;letter-spacing:1px;color:#d5c2e3;margin:18px 0 8px}.score{position:relative;overflow:hidden;background:#302538;border-left:4px solid #ce8fbb;border-radius:10px;margin:8px 0;padding:9px 12px 12px;min-height:107px}.category{position:relative;z-index:1;color:#c5b7dc;font-size:9px;margin-bottom:5px}.scoretable{position:relative;z-index:1;width:100%;table-layout:fixed;border-collapse:collapse}.rank{width:48px;color:#ffda85;font-size:27px;font-weight:bold}.mapcell{padding-right:12px}.map{font-size:15px;font-weight:bold;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.mods{height:24px;white-space:nowrap;overflow:hidden;margin:4px 0;font-size:11px}.mod{width:28px;height:20px;vertical-align:middle;margin-right:2px}.meta{font-size:11px;color:#ffda9d}.points{width:166px;text-align:right;vertical-align:middle;font-size:25px;font-weight:bold;color:#ef9fc7}.points small{font-size:12px}.forecast{font-size:11px;color:#ffda9d;margin-top:8px}.background{position:absolute;top:0;left:0;width:100%;height:100%;object-fit:cover;opacity:.17;z-index:0}.empty{padding:16px;color:#cabbda;font-size:13px}#tt-note{font-size:11px;color:#cabbda;margin-top:8px}</style></head><body><div id='panel' class='panel'>"+Content(json)+"</div><script>"+
        "(function(){var busy=false;function update(){if(busy)return;busy=true;var x=new XMLHttpRequest();x.open('GET','/tiktok/content',true);x.timeout=4000;x.onload=function(){busy=false;if(x.status!==200)return;var d=document.createElement('div');d.innerHTML=x.responseText;var ids=['tt-style','tt-head','tt-stats','tt-best','tt-recent','tt-note'];for(var i=0;i<ids.length;i++){var old=document.getElementById(ids[i]),next=d.querySelector('#'+ids[i]);if(old&&next&&old.innerHTML!==next.innerHTML)old.innerHTML=next.innerHTML;}};x.onerror=x.ontimeout=function(){busy=false;};x.send();}setInterval(update,1000);})();"+
        "</script></body></html>";
    }
}
