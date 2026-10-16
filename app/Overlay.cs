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
        if(ext!=".png"&&ext!=".jpg"&&ext!=".jpeg"&&ext!=".bmp")return "";
        lock(images){
            string url;if(imagePaths.TryGetValue(path,out url))return url;
            if(images.Count>=256){images.Clear();imagePaths.Clear();}
            url="/image/"+Guid.NewGuid().ToString("N");images[url]=path;imagePaths[path]=url;return url;
        }
    }
    public int Port {get;private set;}
    public string Url {get{return "http://127.0.0.1:"+Port+"/";}}
    public void SetState(string json){Interlocked.Exchange(ref state,json);}
    public void Start(string page){
        if(listener!=null)return;
        html=File.ReadAllText(page);
        for(int port=24051;port<=24059;port++){
            var attempt=new TcpListener(IPAddress.Loopback,port);
            try{attempt.Start(16);listener=attempt;Port=port;break;}catch(SocketException){attempt.Stop();}
        }
        if(listener==null)throw new IOException("Overlay ports 24051-24059 are busy.");
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
            else if(parts[1]=="/state"){type="application/json; charset=utf-8";body=state;}
            else if(parts[1]=="/"||parts[1]=="/index.html"){body=html;}
            else if(parts[1].StartsWith("/image/",StringComparison.Ordinal)){
                string path;lock(images){images.TryGetValue(parts[1],out path);}
                if(path!=null&&File.Exists(path)&&new FileInfo(path).Length<=26214400){
                    bytes=File.ReadAllBytes(path);asset=true;
                    string ext=Path.GetExtension(path).ToLowerInvariant();type=ext==".png"?"image/png":ext==".bmp"?"image/bmp":"image/jpeg";
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
