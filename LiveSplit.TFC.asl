/* TFC Autosplitter v0.1a 2023-03-28 by Nomad#6589
Heavily inspired by the Slay The Spire and other existing autosplitters
Created with significant help and guidance from Ero
Thanks to Ero and others in the Speedrun Tool Developement discord

Community / custom maps are not supported by default, but I can add them!
I've included some known split triggers in the Settings,
but to get a map properly supported please contact me on Discord.
 */


// TODO:
// - support counting capture events for maps like cz2, flagrun, avanti, warpath
// - - maybe use counts for maps with start-of-map triggers?
// - figure out correct map triggers for custom maps
// - don't split if timer just started (for maps like hunted)
// - make settings for customized splitters actually work
// - - categorize/sort splitter settings (ADL, CP, CTF?)
// - -add more generic split triggers (cap point 4, cap5, "captured", etc)
// - remove case sensitivity (for triggers and maybe elsewhere)?
// - figure out how gametime works and add support for that
// - - pause gametime on log file close, resume on map start? -cease_fire?
// - figure out how substages work (sub-splits on flag pickup?)
// - check if setting refreshRate higher than 60 catches more log events?


state("hl") {
    // TFC's log message buffer is located at hw.dll+6BB310
    // LOGGING MUST BE ENABLED - use 'log on' in console
    string255 LogLine : "hw.dll", 0x6BB310;
    // In Software graphics mode, address changes to sw.dll+38C1C8
    // string255 SWLogLine : "sw.dll", 0x38C1C8;
}

startup
{
    // Create TimerModel for resetting in `exit`.
    vars.Model = new TimerModel { CurrentState = timer };

    // Settings
    // All triggers could potentially be settings?
    settings.Add("splits", false, "Split overrides for custom maps...");
    settings.SetToolTip("splits",
		"WARNING: Enabling these will override the automatic defaults!\n" +
        "Split triggers should be detected automatically for supported maps without changing these settings.\n" +
        "For unsupported maps, select the appropriate trigger type if possible.\n" +
        "If your map's trigger is not listed here, contact Nomad#6589 to get it added."
    );
    settings.Add("splits_dropoff", false, " dropoff", "splits");
    settings.SetToolTip("splits_dropoff",
		"Used on 2fort, badlands, casbah, crossover2, epicenter, well...\n" + 
        "2fort style 'Team 1 dropoff' or 'team one dropoff' triggers"
	);
    settings.Add("splits_CP3", false, "Capture Point 3", "splits");
    settings.SetToolTip("splits_CP3",
		"Used on avanti, dustbowl...\n" +
        "CP/ADL style maps where 'Capture Point 3' is the victory trigger"
	);
    settings.Add("splits_cz2", false, "#cap5", "splits");
    settings.SetToolTip("splits_cz2",
		"cz2 '#cz_bcap5' trigger\n" +
        "NOTE: this MUST be the last point captured\n" +
        "You may use this setting to finish cz2 on cap5 instead of cap3"
	);
    settings.Add("splits_flagrun", false, "endgame check 2", "splits");
    settings.SetToolTip("splits_flagrun",
		"flagrun style 'endgame check 2' trigger\n" +
        "NOTE: this MUST be the last point captured\n" +
        "You may use this setting to finish flagrun with flag2 instead of flag3"
	);
    settings.Add("splits_hunted", false, "The Hunted's Notepad", "splits");
    settings.SetToolTip("splits_hunted",
		"hunted style 'The Hunted's Notepad' trigger"
	);
    settings.Add("splits_push", false, "ammo_giver", "splits");
    settings.SetToolTip("splits_push",
		"push style 'ammo_giver' trigger"
	);
    settings.Add("splits_ravelin", false, " captured the ", "splits");
    settings.SetToolTip("splits_ravelin",
		"Used on ravelin, but generic enough for some other maps...\n" +
        "ravelin style '%s captured the RED base!' triggers"

	);
    settings.Add("splits_rock2", false, "_scores", "splits");
    settings.SetToolTip("splits_rock2",
		"Used on rock2, but generic enough for some other maps...\n" +
        "rock2 style '#rock_blue_scores' triggers"
	);
    settings.Add("splits_ADL", false, "Cease_Fire", "splits");
    settings.SetToolTip("splits_ADL",
		"Generic, used on some ADL maps...\n" +
        "May only occur 10 seconds after final capture, adjust time if needed"
	);

    settings.Add("resets", true, "Reset when...");
    settings.Add("resets_disconnect", false, "disconnected", "resets");
    settings.SetToolTip("resets_disconnect",
		"Resets when map is changed (leave unchecked for All Maps runs).\n" +
        "Enabling this may save you a keypress during Individual Level runs."
	);
    

}

init
{
    // Current map and objective
    vars.CurrentMap = "";
    vars.CurrentObjective = "";
    // Number of objectives needed
    vars.ObjectivesTotal = 1;
    vars.ObjectivesCompleted = 0;
    
    // Cache for last event
    vars.LastEvent = "";

    // Various trigger messages (see hampalyzer code) go here
    vars.Starter = "Started map";
    vars.StartStrings = new [] {"Started map", "connected, address", "joined team \"SPECTATOR\"" };

    vars.Splitter = "dropoff";
    vars.SplitStrings = new [] {"Team 1 dropoff", "Blue Cap", "Blue_Cap", "BlueCap", "Capture Point"};
    
    vars.Stopper = "disconnected";
    vars.StopStrings = new [] {"disconnected", "Log file closed"};

    // Minimum duration between splits
    vars.SplitCushion = 5.0;

    // Stopwatch workaround
    // vars.Stopwatch = new Stopwatch();
}

update
{
    // Debugging
    // if (current.LogLine != old.LogLine)
    // {
    //     print("DEBUG: Last event line was: " + old.LogLine);
    //     print("DEBUG: Current event line is: " + current.LogLine);
    // }

    // Avoid reading the same event twice
    if (current.LogLine != old.LogLine)
    {
        // Do things based on the current event
        // Identify map
        if (current.LogLine.Contains("Started map"))
        {
            // Reset available objectives
            vars.ObjectivesTotal = 1;
            vars.CurrentMap = current.LogLine.Split('"')[1];
            switch ((string)vars.CurrentMap)
            {
                case "2fort":
                case "badlands":
                case "casbah":
                case "crossover2":
                case "well":
                    vars.CurrentObjective = " dropoff";
                    break;
                case "avanti":
                    vars.CurrentObjective = "Capture Point 3";
                    vars.ObjectivesTotal = 2;
                    break;
                case "dustbowl":
                    vars.CurrentObjective = "Capture Point 3";
                    break;
                case "cz2":
                    // Red team's goals would be '#cz_rcap'
                    vars.CurrentObjective = "#cz_bcap";
                    vars.ObjectivesTotal = 5;
                    break;
                case "epicenter":
                    vars.CurrentObjective = "spawn resupply";
                    vars.ObjectivesTotal = 2;
                    break;
                case "flagrun":
                    vars.CurrentObjective = " endgame check ";
                    vars.ObjectivesTotal = 3;
                    break;
                case "hunted":
                    vars.CurrentObjective = "The Hunted's Notepad";
                    // Trigger occurs on map load
                    vars.ObjectivesTotal = 2;
                    break;
                case "push":
                    vars.CurrentObjective = "ammo_giver";
                    // Trigger occurs on map load
                    vars.ObjectivesTotal = 2;
                    break;
                case "ravelin":
                    vars.CurrentObjective = " captured the ";
                    break;
                case "rock2":
                    vars.CurrentObjective = "_scores";
                    break;
                case "warpath":
                    vars.CurrentObjective = "#inital_spawn_equip"; // typo is theirs, not mine
                    vars.ObjectivesTotal = 2;
                    break;              
                default:
                    print("DEBUG: Unsupported map! Tell Nomad to add " + vars.CurrentMap);
                    break;
            }
            // Debugging
            // print("DEBUG: attempting to update map objective for: " + vars.CurrentMap + "\n" + 
            // "current vars.Splitter value is: " + vars.Splitter + "\n" +
            // "current vars.CurrentObjective value is: " + vars.CurrentObjective);
            
            // Use the identified objective as the splitter string
            vars.Splitter = vars.CurrentObjective;
            // Reset completed objectives
            vars.ObjectivesCompleted = 0;
        }   
    }
    // Don't run if current event log is null.
    return (current.LogLine != null);
}

start
{
    // Debugging
    // print("DEBUG: attempting to START, current event line is: " + current.LogLine);

    // Basic check for trigger string
    return current.LogLine.Contains(vars.Starter);
    // "Started map" - last event before map loads, may inflate times on slow machines?
    // "connected, address" - first event after map loads TODO: compare to bxt

    // Faster method according to https://cc.davelozinski.com/c-sharp/fastest-way-to-check-if-a-string-occurs-within-a-string (2013)
    // return (current.LogLine.Length - current.LogLine.Replace(vars.Starter, String.Empty).Length) / vars.Starter.Length > 0 ? true : false;
}

split
{
    // Debugging
    // print("DEBUG: attempting to SPLIT, current event line is: " + current.LogLine);

    // Never split in the first few seconds
	// if (timer.CurrentTime.RealTime.Value.TotalSeconds < vars.SplitCushion)
	// {
	// 	return;
	// }

    // Attempting to evaluate previous split time to see if we're ready to split again yet...

    // Time lastSplitTime = timer.Run[timer.CurrentSplitIndex-1].SplitTime;
    // Time lastLastSplitTime = timer.Run[timer.CurrentSplitIndex-2].SplitTime;
    // double lastSplitTime = timer.Run[timer.CurrentSplitIndex-1].SplitTime.RealTime.Value.TotalSeconds;
    // double lastLastSplitTime = timer.Run[timer.CurrentSplitIndex-2].SplitTime.RealTime.Value.TotalSeconds;

    // BROKEN - gets stuck once the criteria is met
    // if ((timer.Run[timer.CurrentSplitIndex-1].SplitTime.RealTime.Value.TotalSeconds - timer.Run[timer.CurrentSplitIndex-2].SplitTime.RealTime.Value.TotalSeconds) < vars.SplitCushion)
    // {
    //     print("DEBUG: splitCushionTime: " + vars.SplitCushion + 
    //     "\nlastLastSplitTime: " + timer.Run[timer.CurrentSplitIndex-2].SplitTime.RealTime.Value.TotalSeconds + 
    //     "\nlastSplitTime: " + timer.Run[timer.CurrentSplitIndex-1].SplitTime.RealTime.Value.TotalSeconds +
    //     "\nDifference: " + (timer.Run[timer.CurrentSplitIndex-1].SplitTime.RealTime.Value.TotalSeconds - timer.Run[timer.CurrentSplitIndex-2].SplitTime.RealTime.Value.TotalSeconds));
    //     return;
    // }		
    // if ((timer.Run[timer.CurrentSplitIndex].SplitTime.RealTime.Value.TotalSeconds - timer.Run[timer.CurrentSplitIndex-1].SplitTime.RealTime.Value.TotalSeconds) < vars.SplitCushion)
    // {
    //     // print("DEBUG: splitCushionTime: " + vars.SplitCushion + 
    //     // "\nlastLastSplitTime: " + timer.Run[timer.CurrentSplitIndex-1].SplitTime.RealTime.Value.TotalSeconds + 
    //     // "\nlastSplitTime: " + timer.Run[timer.CurrentSplitIndex].SplitTime.RealTime.Value.TotalSeconds +
    //     // "\nDifference: " + (timer.Run[timer.CurrentSplitIndex].SplitTime.RealTime.Value.TotalSeconds - timer.Run[timer.CurrentSplitIndex-1].SplitTime.RealTime.Value.TotalSeconds));
    //     return;
    // }	

    // Stopwatch workaround
    // if ((timer.CurrentSplitIndex > 0) && (vars.Stopwatch.ElapsedMilliseconds < 7000))
	// {
    //     return;
	// }

    // Basic check for single trigger string
    if ((current.LogLine != old.LogLine) && current.LogLine.Contains(vars.Splitter))
    {
        return (++vars.ObjectivesCompleted >= vars.ObjectivesTotal);
    }
    
    // Basic check for various trigger strings
    // if (vars.LastEvent != current.LogLine && (current.LogLine.Contains("dropoff") || current.LogLine.Contains("Blue Cap") || current.LogLine.Contains("Blue_Cap") || 
    //         current.LogLine.Contains("BlueCap") || current.LogLine.Contains("Capture Point") || current.LogLine.Contains("Cap Point")))
    //         {
    //             vars.LastEvent = current.LogLine;
    //             print("DEBUG: LastEvent (" + vars.LastEvent + "doesn't match LogLine (" + current.LogLine + ")");
    //             return true;
    //         }
    

    // Check array of strings which all count as 'split'
    // string[] splitStrings = vars.SplitStrings; // lambda can't handle the dynamic type returned by vars.SsplitStrings
    // return ssplitStrings.Any(s => current.LogLine.Contains(s));

    // Faster method according to https://cc.davelozinski.com/c-sharp/fastest-way-to-check-if-a-string-occurs-within-a-string (2013)
    // return (current.LogLine.Length - current.LogLine.Replace(vars.Splitter, String.Empty).Length) / vars.Splitter.Length > 0 ? true : false;
}

onSplit
{
    // Stopwatch workaround
    // vars.Stopwatch.Restart();
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
    // return (current.LogLine.Length - current.LogLine.Replace(vars.Stopper, String.Empty).Length) / vars.Stopper.Length > 0 ? true : false;
    return ((current.LogLine.Length - current.LogLine.Replace(vars.Stopper, String.Empty).Length) / vars.Stopper.Length > 0 ? true : false) && settings["resets_disconnect"];
}

exit
{
    // Reset timer if game closed.
    vars.Model.Reset();
}

shutdown
{

}