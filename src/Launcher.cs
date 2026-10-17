using System;
using System.IO;
using System.Diagnostics;
using System.Threading;
using System.Windows.Forms;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Management.Automation.Language;
using Microsoft.PowerShell;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Text.RegularExpressions;
[assembly: System.Reflection.AssemblyTitle("osu! Session Tracker")]
[assembly: System.Reflection.AssemblyVersion("2.2.0.0")]
[assembly: System.Reflection.AssemblyFileVersion("2.2.0.0")]

internal static class Launcher {
    static string Root=AppDomain.CurrentDomain.BaseDirectory;
    static readonly string Client=ReadClient();
    static string ReadClient(){try{return File.ReadAllText(Path.Combine(Root,"app","client.txt")).Trim()=="lazer"?"lazer":"stable";}catch{return "stable";}}
    static int TosuPort=24050;
    static Process ManagedTosu;
    [STAThread]
    static int Main(string[] args){
        Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);
        bool check=Array.IndexOf(args,"--self-test")>=0;
        bool uiTest=Array.IndexOf(args,"--ui-test")>=0;
        try{
            if(check){Validate();File.WriteAllText(Path.Combine(Root,"build-check.txt"),"PASS: files, bundled tosu and PowerShell syntax");return 0;}
            bool first;
            using(var mutex=new Mutex(true,"Local\\OsuSessionTrackerDesktop_"+Client,out first)){
                if(!first){if(!uiTest)MessageBox.Show(L("Трекер уже запущен.","The tracker is already running."),"osu! session tracker");return 0;}
                try{
                    Validate();
                    if(!uiTest)StartTosu();
                    using(var space=RunspaceFactory.CreateRunspace(InitialSessionState.CreateDefault())){
                        space.ApartmentState=ApartmentState.STA;space.ThreadOptions=PSThreadOptions.UseCurrentThread;space.Open();
                        using(var shell=PowerShell.Create()){
                            shell.Runspace=space;
                            shell.AddCommand("Set-ExecutionPolicy").AddParameter("ExecutionPolicy",ExecutionPolicy.Bypass).AddParameter("Scope",ExecutionPolicyScope.Process).AddParameter("Force",true);shell.Invoke();shell.Commands.Clear();shell.Streams.Error.Clear();
                            string script=Path.Combine(Root,"app","Tracker.ps1");
                            if(uiTest)Environment.SetEnvironmentVariable("OSU_TRACKER_UI_TEST","1");
                            if(uiTest){
                                shell.AddScript("param($path) $text=[IO.File]::ReadAllText($path); $text=$text.Replace('$PSScriptRoot',('\"'+[IO.Path]::GetDirectoryName($path)+'\"')); $text=$text.Replace('Play-WelcomeVoice',''); $text=$text.Replace('[void]$form.ShowDialog()','$timer.Stop(); $form.Show(); [Windows.Forms.Application]::DoEvents(); $form.Close(); $form.Dispose()'); Invoke-Expression $text").AddArgument(script);
                            } else shell.AddCommand(script);
                            shell.Invoke();
                            if(shell.HadErrors){
                                string error="";foreach(var item in shell.Streams.Error)error+=item.ToString()+Environment.NewLine;
                                throw new Exception(error);
                            }
                        }
                    }
                    if(uiTest)File.WriteAllText(Path.Combine(Root,"ui-check.txt"),"PASS: compiled host created and closed tracker UI");
                }finally{StopTosu();mutex.ReleaseMutex();}
            }
            return 0;
        }catch(Exception error){
            string log=Path.Combine(Root,"launcher-error.txt");
            try{File.WriteAllText(log,error.ToString());}catch{}
            if(!check&&!uiTest)MessageBox.Show(L("Не удалось запустить трекер. Подробности: ","Could not start the tracker. Details: ")+log+"\n\n"+error.Message,"osu! session tracker",MessageBoxButtons.OK,MessageBoxIcon.Error);
            return 1;
        }
    }
    static void Validate(){
        foreach(string file in new[]{"app/client.txt","app/Tracker.ps1","app/Features.ps1","app/Localization.ps1","app/Desktop.ps1","app/Feed.cs","app/Overlay.cs","app/Theme.cs","app/assets/mascot.png","app/assets/menu-background.png","app/assets/overlay.html","app/assets/welcome-ja.wav","tosu/tosu.exe"})
            if(!File.Exists(Path.Combine(Root,file)))throw new FileNotFoundException(L("Распакуй всю папку программы. Не найден файл: ","Extract the entire app folder. Missing file: ")+file);
        foreach(string file in Directory.GetFiles(Path.Combine(Root,"app"),"*.ps1")){
            Token[] tokens;ParseError[] errors;Parser.ParseFile(file,out tokens,out errors);
            if(errors.Length>0)throw new Exception(file+": "+errors[0].Message);
        }
    }
    static string L(string ru,string en){
        try{if(Regex.IsMatch(File.ReadAllText(Path.Combine(Root,"app","settings.json")),"\"language\"\\s*:\\s*\"en\""))return en;}catch{}
        return ru;
    }
    static void StartTosu(){
        if(ManagedTosu!=null){if(!ManagedTosu.HasExited)return;ManagedTosu.Dispose();ManagedTosu=null;}
        // Reuse an existing local server even when its process has another name.
        if(PortInUse(TosuPort)){AdoptExistingTosu();return;}
        var existing=Process.GetProcessesByName("tosu");bool running=existing.Length>0;
        foreach(var process in existing)process.Dispose();
        if(running){AdoptExistingTosu();return;}
        string path=Path.Combine(Root,"tosu","tosu.exe");
        var start=new ProcessStartInfo(path){WorkingDirectory=Path.GetDirectoryName(path),UseShellExecute=false,CreateNoWindow=true,WindowStyle=ProcessWindowStyle.Hidden};
        ManagedTosu=Process.Start(start);
    }
    static void AdoptExistingTosu(){
        var processes=Process.GetProcessesByName("tosu");
        if(processes.Length==1){ManagedTosu=processes[0];return;}
        string bundled=Path.Combine(Root,"tosu","tosu.exe");
        foreach(var process in processes){
            try{if(ManagedTosu==null&&String.Equals(process.MainModule.FileName,bundled,StringComparison.OrdinalIgnoreCase)){ManagedTosu=process;continue;}}catch{}
            process.Dispose();
        }
    }
    static void StopTosu(){
        var process=ManagedTosu;ManagedTosu=null;if(process==null)return;
        // Both editions can share tosu. The final running tracker closes it.
        string other=Client=="lazer"?"OsuSessionTracker":"OsuSessionTrackerLazer";
        var peers=Process.GetProcessesByName(other);bool otherRunning=false;
        foreach(var peer in peers){if(peer.Id!=Process.GetCurrentProcess().Id)otherRunning=true;peer.Dispose();}
        if(otherRunning){process.Dispose();return;}
        try{if(!process.HasExited){if(!process.CloseMainWindow()||!process.WaitForExit(1000)){process.Kill();process.WaitForExit(1500);}}}catch(InvalidOperationException){}catch(System.ComponentModel.Win32Exception){}
        finally{process.Dispose();}
    }
    static bool PortInUse(int port){
        try{
            foreach(var endpoint in IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners()){
                if(endpoint.Port==port&&(IPAddress.IsLoopback(endpoint.Address)||endpoint.Address.Equals(IPAddress.Any)||endpoint.Address.Equals(IPAddress.IPv6Any)))return true;
            }
            return false;
        }catch(NetworkInformationException){}catch(System.Security.SecurityException){}
        // Restricted Windows environments may deny the listener inventory.
        try{using(var client=new TcpClient()){
            var pending=client.BeginConnect(IPAddress.Loopback,port,null,null);
            using(var done=pending.AsyncWaitHandle){if(!done.WaitOne(500))return false;}
            client.EndConnect(pending);return client.Connected;
        }}catch(SocketException){}catch(System.Security.SecurityException){}
        return false;
    }
}
