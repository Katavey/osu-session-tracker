using System;
using System.Collections.Generic;
using System.IO;
using System.Net.WebSockets;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

public sealed class FeedSample {
    public string Json;
    public int Generation;
    public FeedSample(string json,int generation){Json=json;Generation=generation;}
}
public sealed class TosuFeed : IDisposable {
    readonly object gate=new object();
    readonly Queue<FeedSample> transitions=new Queue<FeedSample>();
    static readonly Regex statePattern=new Regex("\"state\"\\s*:\\s*\\{[^}]*\"number\"\\s*:\\s*(\\d+)",RegexOptions.Compiled);
    FeedSample latest,delivered;
    int previousState=-1,generation;
    long received,dropped;
    DateTime lastReceived=DateTime.MinValue;
    CancellationTokenSource cancellation;
    ClientWebSocket socket;
    Task worker;
    volatile string status="Disconnected";
    volatile string lastError="";
    public string Status {get{return status;}}
    public string LastError {get{return lastError;}}
    public long ReceivedCount {get{lock(gate)return received;}}
    public long DroppedTransitions {get{lock(gate)return dropped;}}
    public double LatestAgeMs {get{lock(gate)return lastReceived==DateTime.MinValue?-1:(DateTime.UtcNow-lastReceived).TotalMilliseconds;}}
    void Enqueue(FeedSample sample){
        if(sample==null)return;
        if(transitions.Count>=2048){transitions.Dequeue();dropped++;}
        transitions.Enqueue(sample);
    }
    // Keep the final gameplay snapshot and every state transition, but coalesce
    // repetitive live telemetry. Drawing a slow window cannot stall the socket.
    public void AcceptPacket(string json){
        var match=statePattern.Match(json);if(!match.Success)return;
        int state=int.Parse(match.Groups[1].Value);
        lock(gate){
            var sample=new FeedSample(json,generation);
            if(state!=previousState){Enqueue(latest);Enqueue(sample);}
            latest=sample;previousState=state;received++;lastReceived=DateTime.UtcNow;
        }
    }
    public FeedSample[] Drain(){
        lock(gate){
            var result=new List<FeedSample>(transitions.Count+1);
            while(transitions.Count>0){var sample=transitions.Dequeue();if(!Object.ReferenceEquals(sample,delivered)){result.Add(sample);delivered=sample;}}
            if(latest!=null&&!Object.ReferenceEquals(latest,delivered)){result.Add(latest);delivered=latest;}
            return result.ToArray();
        }
    }
    public void Start(string url){
        if(worker!=null)throw new InvalidOperationException("Feed already started");
        cancellation=new CancellationTokenSource();
        worker=Task.Run(()=>ReadLoop(new Uri(url),cancellation.Token));
    }
    async Task ReadLoop(Uri url,CancellationToken token){
        while(!token.IsCancellationRequested){
            try{
                status="Connecting";
                using(var client=new ClientWebSocket()){
                    socket=client;client.Options.KeepAliveInterval=TimeSpan.FromSeconds(15);
                    using(var connect=CancellationTokenSource.CreateLinkedTokenSource(token)){
                        connect.CancelAfter(5000);await client.ConnectAsync(url,connect.Token).ConfigureAwait(false);
                    }
                    lock(gate){generation++;latest=null;delivered=null;previousState=-1;}
                    status="Connected";lastError="";
                    byte[] buffer=new byte[65536];
                    using(var message=new MemoryStream()){
                        while(!token.IsCancellationRequested&&client.State==WebSocketState.Open){
                            var part=await client.ReceiveAsync(new ArraySegment<byte>(buffer),token).ConfigureAwait(false);
                            if(part.MessageType==WebSocketMessageType.Close)break;
                            if(part.MessageType!=WebSocketMessageType.Text)continue;
                            message.Write(buffer,0,part.Count);
                            if(message.Length>4194304)throw new IOException("tosu message exceeded 4 MB");
                            if(part.EndOfMessage){AcceptPacket(Encoding.UTF8.GetString(message.GetBuffer(),0,(int)message.Length));message.SetLength(0);}
                        }
                    }
                }
            }catch(Exception error){if(!token.IsCancellationRequested)lastError=error.Message;}
            finally{socket=null;status="Disconnected";}
            if(!token.IsCancellationRequested){try{await Task.Delay(1500,token).ConfigureAwait(false);}catch(OperationCanceledException){}}
        }
    }
    public void Dispose(){
        if(cancellation==null)return;
        cancellation.Cancel();var current=socket;if(current!=null)try{current.Abort();}catch{}
        if(worker!=null)try{worker.Wait(1000);}catch{}
        cancellation.Dispose();cancellation=null;
    }
}
