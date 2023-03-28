/* TFC Autosplitter v0.1a 2023-03-28 by Nomad 
Heavily inspired by the Slay The Spire and other existing autosplitters
Created with significant help and guidance from Ero
Thanks to Ero and others in the Speedrun Tool Developement discord
 */

state("hl") {
    // TFC's log message buffer is located at hw.dll+6BB310
    // LOGGING MUST BE ENABLED - use 'log on' in console
    string255 LogLine : "hw.dll", 0x6BB310;
}

startup
{
    // Create TimerModel for resetting in `exit`.
    vars.Model = new TimerModel { CurrentState = timer };
}

init
{
    // Various trigger messages (see hampalyzer code) go here
    vars.Starter = "Server cvars end";
    vars.StartStrings = new [] {"Server cvars end", "Server cvar \"sv_maxspeed\"", "Started map" };

    vars.Splitter = "dropoff";
    vars.SplitStrings = new [] {"Team 1 dropoff", "Blue Cap", "Blue_Cap", "BlueCap", "Capture Point"};
    
    vars.Stopper = "disconnected";
    vars.StopStrings = new [] {"disconnected", "Log file closed"};
}

update
{
    // Debugging
    // if (current.LogLine != old.LogLine)
    // {
    //     print("DEBUG: Last event line was: " + old.LogLine);
    //     print("DEBUG: Current event line is: " + current.LogLine);
    // }
    
    // Don't run if current event log is null.
    return (current.LogLine != null);       
}

start
{
    // Debugging
    // print("DEBUG: attempting to START, current event line is: " + current.LogLine);

    // Basic check for trigger string
    // return current.LogLine.Contains("Server cvars end");

    // Check array of strings which all count as 'start'
    // string[] startStrings = vars.StartStrings; // lambda can't handle the dynamic type returned by vars.StartStrings
    // return startStrings.Any(s => current.LogLine.Contains(s));

    // Faster method according to https://cc.davelozinski.com/c-sharp/fastest-way-to-check-if-a-string-occurs-within-a-string (2013)
    return (current.LogLine.Length - current.LogLine.Replace(vars.Starter, String.Empty).Length) / vars.Starter.Length > 0 ? true : false;
}

split
{
    // Debugging
    // print("DEBUG: attempting to SPLIT, current event line is: " + current.LogLine);
    
    // Basic check for trigger string
    return (current.LogLine.Contains("dropoff") || current.LogLine.Contains("Blue Cap") || current.LogLine.Contains("Blue_Cap") || 
            current.LogLine.Contains("BlueCap") || current.LogLine.Contains("Capture Point") || current.LogLine.Contains("Cap Point"));

    // Check array of strings which all count as 'split'
    // string[] splitStrings = vars.SplitStrings; // lambda can't handle the dynamic type returned by vars.SsplitStrings
    // return ssplitStrings.Any(s => current.LogLine.Contains(s));

    // Faster method according to https://cc.davelozinski.com/c-sharp/fastest-way-to-check-if-a-string-occurs-within-a-string (2013)
    // return (current.LogLine.Length - current.LogLine.Replace(vars.Splitter, String.Empty).Length) / vars.Splitter.Length > 0 ? true : false;
}

reset
{
    // Debugging
    // print("DEBUG: attempting to RESET, current event line is: " + current.LogLine);

    // Basic check for trigger string
    // return current.LogLine.Contains("stop");
    
    // Check array of strings which all count as 'stop'
    // string[] stopStrings = vars.StopStrings; // lambda can't handle the dynamic type returned by vars.StopStrings
    // return stopStrings.Any(s => current.LogLine.Contains(s)); 
    
    // Faster method according to https://cc.davelozinski.com/c-sharp/fastest-way-to-check-if-a-string-occurs-within-a-string (2013)
    return (current.LogLine.Length - current.LogLine.Replace(vars.Stopper, String.Empty).Length) / vars.Stopper.Length > 0 ? true : false;
}

exit
{
    // Reset timer if game closed.
    vars.Model.Reset();
}

shutdown
{

}
