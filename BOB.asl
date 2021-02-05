state("BOB_the_adventures_of_BOB")
{
	byte sceneID : 0x001AF2F8;
}

startup
{
	settings.Add("split_on_every_level", true, "Split on every level");
}

start
{
	return current.sceneID == 0x00 && old.sceneID == 0x0A;
}

reset
{
	return current.sceneID == 0x0A && ((old.sceneID & 0x0E) != 0x0A);
}

split
{
	return current.sceneID != old.sceneID && (settings["split_on_every_level"] || old.sceneID == 0x0B);
}
