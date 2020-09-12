state("Sensorium-Win64-Shipping") { }

startup
{
	settings.Add("split_ach", true, "Split on achievements");
		settings.Add("split_tutorial", true, "Tutorial area", "split_ach");
		settings.Add("split_sense", true, "Sense areas", "split_ach");
			settings.Add("split_touch", true, "Touch", "split_sense");
			settings.Add("split_taste", true, "Taste", "split_sense");
			settings.Add("split_smell", true, "Smell", "split_sense");
			settings.Add("split_sight", true, "Sight", "split_sense");
			settings.Add("split_hearing", true, "Hearing", "split_sense");
		settings.Add("split_end", true, "End", "split_ach");
		settings.Add("split_bonus", false, "Bonuses", "split_ach");
			settings.Add("split_touch_bonus", true, "Touch Bonus (⅄)", "split_bonus");
			settings.Add("split_taste_bonus", true, "Taste Bonus", "split_bonus");
			settings.Add("split_smell_bonus", true, "Smell Bonus", "split_bonus");
			settings.Add("split_sight_bonus", true, "Sight Bonus", "split_bonus");
			settings.Add("split_hearing_bonus", true, "Hearing Bonus", "split_bonus");
		settings.Add("split_power_hub", false, "Power Hub (∓)", "split_ach");
		settings.Add("split_toggle_vault", false, "Toggle Vault", "split_ach");
		settings.Add("split_timer_vault", false, "Timer Vault", "split_ach");
	settings.Add("split_other", false, "Split on other side puzzles/secrets");
		settings.Add("split_sight_side", true, "Sight area side puzzle (|||)", "split_other");
		settings.Add("split_taste_side", true, "Taste area side puzzle (◯)", "split_other");
		settings.Add("split_piano", true, "Piano", "split_other");
		settings.Add("split_dev_museum", true, "Development Museum", "split_other");
		settings.Add("split_entry_door", true, "Entry door secret (□)", "split_other");
		settings.Add("split_parkour", true, "Parkour secret (◠)", "split_other");
		settings.Add("split_end_game", true, "End game secret (⽘)", "split_other");
		settings.Add("split_park_activation", true, "Park activation puzzle", "split_other");
	settings.Add("split_smell_clue", false, "Split on Smell clues");
		settings.Add("split_green_smell", true, "Green smell", "split_smell_clue");
		settings.Add("split_yellow_smell", true, "Yellow smell", "split_smell_clue");
		settings.Add("split_blue_smell", true, "Blue smell", "split_smell_clue");
		settings.Add("split_red_smell", true, "Red smell", "split_smell_clue");
		settings.Add("split_purple_smell", true, "Purple smell", "split_smell_clue");
	settings.Add("split_end_on_completion_only", false, "Only split on game end after 100% completion");

	vars.ptr = null;
	vars.scanner = null;
	vars.watcher = null;

	vars.scan = new Action(()
	=> {
		if (vars.ptr == IntPtr.Zero)
		{
			vars.ptr = vars.scanner.Scan(vars.scanTarget, 0x08);
			if (vars.ptr != IntPtr.Zero)
				vars.watcher = new MemoryWatcher<ulong>(vars.ptr);
		}
	});
}

init
{
	vars.ptr = IntPtr.Zero;
	vars.scanner = new SignatureScanner(game, modules.First().BaseAddress,
		modules.First().ModuleMemorySize
	);
	vars.watcher = null;
	vars.scanTarget = new SigScanTarget(8, // Targeting byte 8
		0x37, 0x13, 0x37, 0x13, 0x37, 0x13, 0x37, 0x13 // Magic number
	);

	vars.scan();
	if (vars.ptr == IntPtr.Zero)
		print("Could not find magic number");

	vars.ignoreReset = false;
	vars.startAfterLoad = false;

	vars.settingNames = new Dictionary<long, string>
	{
		{ 0x01, "split_tutorial" },
		{ 0x02, "split_touch" },
		{ 0x04, "split_taste" },
		{ 0x08, "split_smell" },
		{ 0x10, "split_sight" },
		{ 0x20, "split_hearing" },
		// Game ending is handled elsewhere
		{ 0x80, "split_touch_bonus" },
		{ 0x0100, "split_taste_bonus" },
		{ 0x0200, "split_smell_bonus" },
		{ 0x0400, "split_sight_bonus" },
		{ 0x0800, "split_hearing_bonus" },
		{ 0x1000, "split_power_hub" },
		{ 0x2000, "split_toggle_vault" },
		{ 0x4000, "split_timer_vault" },
		{ 0x8000, "split_sight_side" },
		{ 0x010000, "split_taste_side" },
		{ 0x020000, "split_piano" },
		{ 0x040000, "split_dev_museum" },
		{ 0x080000, "split_entry_door" },
		{ 0x100000, "split_parkour" },
		{ 0x200000, "split_end_game" },
		{ 0x400000, "split_park_activation" },
		{ 0x800000, "split_green_smell" },
		{ 0x01000000, "split_yellow_smell" },
		{ 0x02000000, "split_blue_smell" },
		{ 0x04000000, "split_red_smell" },
		{ 0x08000000, "split_purple_smell" }
	};
}

start
{
	if (0 < (vars.watcher.Old & 0x0200000000)
		&& (vars.watcher.Current & 0x0200000000) == 0)
	{
		vars.startAfterLoad = true;
	}
	else if (vars.startAfterLoad
		&& (vars.watcher.Old & 0x0100000000) == 0
		&& 0 < (vars.watcher.Current & 0x0100000000))
	{
		vars.startAfterLoad = false;
		return true;
	}
}

update
{
	vars.scan();

	if (vars.ptr == IntPtr.Zero)
		return false;

	vars.watcher.Update(game);
}

reset
{
	if ((vars.watcher.Old & 0x0200000000) == 0
		&& 0 < (vars.watcher.Current & 0x0200000000))
	{
		if (vars.ignoreReset)
			vars.ignoreReset = false;
		else
			return true;
	}
}

split
{
	var newlyCheckedFlags = (int)(~vars.watcher.Old & vars.watcher.Current);

	// If area flag byte has changed
	if (0 < newlyCheckedFlags)
	{
		// If game ended
		if (0 < (newlyCheckedFlags & 0x40)
			&& (!settings["split_end_on_completion_only"] || (vars.watcher.Current & 0x0FFFFFFF) == 0x0FFFFFFF))
		{
			vars.ignoreReset = true; // Don't reset after the game was beaten
			return settings["split_end"];
		}

		// Check if corresponding setting is activated
		return settings[vars.settingNames[newlyCheckedFlags]];
	}
}

isLoading
{
	return (vars.watcher.Current & 0x0100000000) == 0;
}
