/* TFC Autosplitter v1.0 2023-04-06 by Nomad#6589
Created with significant help and guidance from other people.
Refactor based almost entirely on Ero's input - thank you Ero!
Thanks also to everyone in the Speedrun Tool Developement discord.
 */

/* Notes:
My goal was to create a non-invasive (non-hook) alternative to BXT.
BXT is great at what it does, but some players in the TFC community
may be uncomfortable using it due to the VAC warning.
Based on my understanding of how VAC works this autosplitter should
be safe to use - it watches one of the game's memory offsets (which
VAC can see), but it's just the offset for the log output.
If you have any questions or concerns please feel free to contact me.

In terms of timing accuracy, the specific triggers used by BXT are
slightly different than what are used in this autosplitter, which
means that the final time isn't always going to be identical.
For 100% accurate timings, down to the nanosecond, I recommend using
BXT with full integration (autorecording, timing info in demos, etc).
For the average runner, I think this should be pretty darn close. :)

Known issues:
Not all maps are currently supported, but we can add more!
Contact me on Discord to add support for a map, it's quick and easy.

Most maps expect a certain number of objective completion events.
Some maps activate completion events every time the player spawns 
(for various reasons). Respawning without restarting the map may
cause unexpected issues in some cases (epicenter, hunted, push, warpath).

Some maps only support one team (cz2 must be run as Blue team).
 */

state("hl")
{
    // TFC's log message buffer is located at hw.dll+6BB310.
    // LOGGING MUST BE ENABLED: use 'log on' in console.
    string255 LogLine : "hw.dll", 0x6BB310;
    
    // In Software graphics mode, address changes to sw.dll+38C1C8.
    // string255 SWLogLine : "sw.dll", 0x38C1C8;
}

startup
{
    // Need a timer to keep track of the time
    vars.Model = new TimerModel { CurrentState = timer };

    // Table to track map names, triggers, and objective count.
    // (the count address various map-specific quirks)
    vars.Splits = new Dictionary<string, Tuple<string, int, string>>
    {
        { "2fort",              Tuple.Create(" dropoff",             1, " Flag\""                 ) }, // (Valve)
        { "badlands",           Tuple.Create(" dropoff",             1, " Flag\""                 ) }, // (Valve)
        { "casbah",             Tuple.Create(" dropoff",             1, " Flag\""                 ) }, // (Valve)
        { "crossover2",         Tuple.Create(" dropoff",             1, " Flag\""                 ) }, // (Valve)
        { "well",               Tuple.Create(" dropoff",             1, " flag\""                 ) }, // (Valve)
        { "alchimy_l2",         Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "fry_baked_lg",       Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "mortality_l",        Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "openfire_lowgrens",  Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "phantom",            Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "pitfall",            Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "schtop",             Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "shutdown2_lg",       Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "siege",              Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "ss_nyx_ectfc",       Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "stowaway2_lg",       Tuple.Create(" dropoff",             1, " Flag\""                 ) },
        { "avanti",             Tuple.Create("Capture Point 3",      2, "\"Flag "                 ) }, // (Valve)
        { "dustbowl",           Tuple.Create("Capture Point 3",      1, "#dustbowl_blue_secures_" ) }, // (Valve)
        { "cz2",                Tuple.Create("#cz_bcap",             5, " flag "                  ) }, // (Valve)
        { "epicenter",          Tuple.Create("spawn resupply",       2, " Flag\""                 ) }, // (Valve)
        { "flagrun",            Tuple.Create(" endgame check ",      3, "flag "                   ) }, // (Valve)
        { "hunted",             Tuple.Create("The Hunted's Notepad", 2, "(N/A, no split trigger)" ) }, // (Valve)
        { "push",               Tuple.Create("ammo_giver",           2, "\"flag\""                ) }, // (Valve)
        { "ravelin",            Tuple.Create(" captured the ",       1, " Flag\""                 ) }, // (Valve)
        { "rock2",              Tuple.Create("_scores",              1, "\"goalitem\""            ) }, // (Valve)
        { "warpath",            Tuple.Create("#inital_spawn_equip",  2, " cap, move "             ) }, // (Valve)
        { "2kfort5",            Tuple.Create("Capture Point",        1, " Flag\""                 ) },
        { "destroy_l",          Tuple.Create("Capture Point",        1, " Flag\""                 ) },
        { "monkey_l",           Tuple.Create("Cap Point",            1, " Flag\""                 ) },
        { "monkey_lg",          Tuple.Create("Cap Point",            1, " Flag\""                 ) },
        { "raiden7",            Tuple.Create("Capture Point",        1, " Flag"                   ) },
        { "siden",              Tuple.Create("Capture Point",        1, " Flag"                   ) },
        { "stormz2",            Tuple.Create("Capture Point",        1, " Flag\""                 ) },
        { "(unknown)",          Tuple.Create(" dropoff",             1, " Flag"                   ) },
    };

    // Reset automatically when the map ends? Off by default (breaks All Maps runs).
    settings.Add("autoreset", false, "Reset on disconnect");
    settings.SetToolTip("autoreset", "This should NOT be enabled for All Maps runs.\n" +
    "May be convenient when running individual levels.");

    // Split on things like flag pickups? Off by default.
    settings.Add("subsplits", false, "Subsplit on objective pickup");
    settings.SetToolTip("subsplits", "Subsplits must be added to Splits list for this to work.");
    // Populate subsplit settings.
    foreach (KeyValuePair<string, Tuple<string, int, string>> split in vars.Splits)
        settings.Add("split-" + split.Key + "-" + split.Value.Item3, false, split.Key, "subsplits");
    
    // Split on map objectives? On by default (required for autosplitter to work).
    settings.Add("splits", true, "Autosplit when completing maps");
    settings.SetToolTip("splits", "All maps should always be enabled.\nTo add a new map, contact Nomad.");
    // Populate Splits settings.
    foreach (KeyValuePair<string, Tuple<string, int, string>> split in vars.Splits)
        settings.Add("split-" + split.Key + "-" + split.Value.Item2, true, split.Key, "splits");
}

init
{
    // Event that includes the map name.
    vars.MapLoadEvent = " Started map ";
    
    // Event that starts the timer. Available options are...
    // "connected, address" - first event after map loads (before bxt).
    // "entered the game" - appears to be what bxt uses, but we can't see it...
    // "joined team \"SPECTATOR\"" - next event we can see (after bxt).
    vars.ReadyEvent = " connected, address ";
    
    // Event that indicates map has ended.
    vars.ResetEvent = "\" disconnected";
}

update
{
    // Don't do anything without a new, valid log line.
    if (old.LogLine == current.LogLine || current.LogLine == null)
        return false;

    // Unpause Game Time, grab the map name when we see it, and reset the objectives counter.
    if (current.LogLine.Contains(vars.MapLoadEvent))
    {
        vars.Loading = false;
        vars.CompletedObjectives = 0;
        vars.Map = current.LogLine.Split('"')[1];
        
        // Set the objective (default value if map is unknown).
        if (!vars.Splits.ContainsKey(vars.Map))
        {
            print("WARNING: Map is not supported! Autosplits may not work correctly.\n" +
            "Please contact Nomad#6589 to add support for " + vars.Map);
            vars.Map = "(unknown)";
        }
        vars.Objective = vars.Splits[vars.Map].Item1;

        // Set the subsplit event
        vars.Subsplit = vars.Splits[vars.Map].Item3;
    }

    // Debugging
    print("DEBUG: current.LogLine = " + current.LogLine);
}

start
{
    // Start the timer.
    return current.LogLine.Contains(vars.ReadyEvent);
}

split
{
    // Check if the current map's objective event just happened.
    if (current.LogLine.Contains(vars.Objective))
    {
        // Count how many times the event has happened
        vars.CompletedObjectives++;
        
        // Split if everything matches the vars.Splits table.
        return settings["split-" + vars.Map + "-" + vars.CompletedObjectives];
    }

    // Check for subsplit activation
    if (settings["subsplits"] && current.LogLine.Contains(vars.Subsplit))
        return true;
}

isLoading
{
    // Pause timer between maps
    if (!vars.Loading && current.LogLine.Contains(vars.ResetEvent))
        vars.Loading = true;

    return vars.Loading;
}

reset
{
    // Reset timer on map end if this setting is enabled.
    return settings["autoreset"] && current.LogLine.Contains(vars.ResetEvent);
}
