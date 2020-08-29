state("Sensorium-Win64-Shipping") { }

startup
{
	settings.Add("split_intro", true, "Split on intro area");
	settings.Add("split_sense", true, "Split on sense areas");
		settings.Add("split_touch", true, "Touch", "split_sense");
		settings.Add("split_taste", true, "Taste", "split_sense");
		settings.Add("split_smell", true, "Smell", "split_sense");
		settings.Add("split_sight", true, "Sight", "split_sense");
		settings.Add("split_hearing", true, "Hearing", "split_sense");
	settings.Add("split_end", true, "Split on end");

	vars.ptr = null;
	vars.scanner = null;
	vars.watcher = null;

	// This function always has to return something or else the return keyword
	// doesn't work
	vars.scan = (Func<bool>)(()
	=> {
		if (vars.ptr != IntPtr.Zero)
			return false;

		vars.ptr = vars.scanner.Scan(vars.scanTarget);
		if (vars.ptr != IntPtr.Zero)
			vars.watcher = new MemoryWatcher<ulong>(vars.ptr);

		return false;
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
}

start
{
	// Start when game isn't loading and all other flags are 0
	return vars.watcher.Old == 0 && vars.watcher.Current == 0x0100000000;
}

update
{
	vars.scan();

	if (vars.ptr == IntPtr.Zero)
		return false;

	vars.watcher.Update(game);

	//print(vars.watcher.Current.ToString("X16"));
}

reset
{
	// In the intro area this reset function doesn't work :/
	return vars.watcher.Old != 0x0100000000 && vars.watcher.Old != 0
		&& vars.watcher.Current == 0;
}

split
{
	var newlyCheckedFlags = (byte)(~vars.watcher.Old & vars.watcher.Current);

	// If area flag byte has changed
	if (0 < newlyCheckedFlags)
		return (settings["split_intro"] && 0 < (newlyCheckedFlags & 0x01))
			|| (settings["split_touch"] && 0 < (newlyCheckedFlags & 0x02))
			|| (settings["split_taste"] && 0 < (newlyCheckedFlags & 0x04))
			|| (settings["split_smell"] && 0 < (newlyCheckedFlags & 0x08))
			|| (settings["split_sight"] && 0 < (newlyCheckedFlags & 0x10))
			|| (settings["split_hearing"] && 0 < (newlyCheckedFlags & 0x20))
			|| (settings["split_end"] && 0 < (newlyCheckedFlags & 0x40));
}

isLoading
{
	return (vars.watcher.Current & 0x0100000000) == 0;
}
