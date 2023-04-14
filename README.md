## TFC Autosplitter

[LiveSplit](http://livesplit.org/) [Autosplitter](https://github.com/LiveSplit/LiveSplit.AutoSplitters) for [Team Fortress Classic](https://store.steampowered.com/app/20/Team_Fortress_Classic/) [speedrunning](https://www.speedrun.com/tfc)

- https://www.speedrun.com/tfc

## Features

- Automatically start the timer when the map loads.
- Automatically split when the map objective is completed.
- Automatically pause the timer while loading. 
  - To enable this feature: Right click -> Compare Against -> Game Time (or Right click -> Edit Layout -> Layout Settings -> Timer tab -> Timing Method: Game Time)
- (Optional) Subsplit on events like flag pickup (off by default, intended for use with subsplit-included splits lists).
- (Optional) automatically reset the timer on map restart (off by default, intended for individual levels, disable this for All Maps runs).

## Installation 

- Go to "Edit Splits.." in LiveSplit
- Enter the name of the game (Team Fortress Classic) in "Game Name"
  - This must be entered correctly for LiveSplit to know which script to load
- Click the "Activate" button to download and enable the autosplitter script
  - If successful, the Settings button should be available
  - If you ever want to stop using the autosplitter altogether, just click "Deactivate"

## Manual Installation (skip this if you used the 'Activate' Button)

- Download https://raw.githubusercontent.com/Nomad7/TFCautosplitter/main/LiveSplit.TFC.asl
- Go to "Edit Layout..." in LiveSplit
- Click the '+' button to Add a Control: Scriptable Componment
- In the 'Script Path' field Browse to the "LiveSplit.TFC.asl" file you downloaded
  - If successful, the Settings should be visible
  
## Set-up (if auto-installed)

- Go to "Edit Splits..." in LiveSplit
- Click "Settings" to configure the autosplitter if desired
  - If desired, you may enable/disable automatic resets
  - If desired, you may enable/disable subsplits
  - Autosplit on map completion should **always be enabled for all maps.**
  - Use `Reset to Default` to return to normal (no autoresets, no subsplits)
  
## Notes

My goal was to create a non-invasive (non-hook) alternative to [BXT](https://github.com/YaLTeR/BunnymodXT).
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

## Known issues

- If you encounter any issues at all, please let me know.

Not all maps are currently supported, but we can add more!
Contact me on Discord to add support for a map, it's quick and easy.

Most maps expect a certain number of objective completion events.
Some maps activate completion events every time the player spawns 
(for various reasons). Respawning without restarting the map may
cause unexpected issues in some cases (epicenter, hunted, push, warpath).

Some maps only support one team (cz2 must be run as Blue team).

## Thanks

- Thanks to Ero and everyone on the [Speedrun Tool Development Discord](https://discord.gg/N6wv8pW)

## Contact

If you encounter any issues at all, or have feature requests, please let me know! 

- Nomad#6589 on Discord
