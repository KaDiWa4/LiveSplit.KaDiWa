state("InnerSpace")
{
	string32 sceneName : 0x0144F9D0, 0x48, 0x48;
}

startup
{
	settings.Add("Hub World", true, "Split on entering Sunchamber");
	settings.Add("Ice World", true, "Split on entering Mornsea");
	settings.Add("Crab World", true, "Split on entering Eventide");
	settings.Add("AI World", true, "Split on entering Duskprism");
	settings.Add("Finale World", true, "Split on entering The Narrow Sky");
	settings.Add("Credits", true, "Split on reaching the credits");
	settings.Add("reset_save", false, "Reset save file 1 on reset");
	settings.SetToolTip("reset_save", "Copy folder 'clear_save' to InnerSpace folder 'Ancient' when resetting on the title screen");

	vars.innerSpaceDir = null;
	vars.clearSaveDir = null;
	vars.ancientDir = null;

	vars.hasAddedResetHandler = false;
}

init
{
	if (!vars.hasAddedResetHandler)
	{
		vars.hasAddedResetHandler = true;
		timer.OnReset += (object sender, LiveSplit.Model.TimerPhase e) =>
		{
			var validSceneName = false;
			try
			{
				validSceneName = current.sceneName.Length > 0 && current.sceneName != "Temp";
			}
			catch {}

			if (!validSceneName)
			{
				print("invalid scene name");
			}
			else if (settings["reset_save"] && current.sceneName == "Start Screen")
			{
				if (vars.innerSpaceDir == null)
				{
					vars.innerSpaceDir = Environment.ExpandEnvironmentVariables(@"%USERPROFILE%\AppData\LocalLow\PolyKnight Games\InnerSpace");
					vars.clearSaveDir = vars.innerSpaceDir + @"\clear_save";
					vars.ancientDir = vars.innerSpaceDir + @"\Ancient";
				}

				if (Directory.Exists(vars.clearSaveDir))
				{
					print("clearing folder 'Ancient'");
					if (Directory.Exists(vars.ancientDir))
					{
						foreach (var path in Directory.GetFiles(vars.ancientDir))
						{
							File.Delete(path);
						}
					}
					else
					{
						Directory.CreateDirectory(vars.ancientDir);
					}

					foreach (var path in Directory.GetFiles(vars.clearSaveDir))
					{
						File.Copy(path, path.Replace(vars.clearSaveDir, vars.ancientDir));
					}
				}
				else
				{
					print("cannot find folder 'clear_save'");
				}
			}
		};
	}

	vars.prevWorldName = null;
	vars.setPrevWorldName = null;
	vars.leftInputTutorial = false;
}

update
{
	if (vars.setPrevWorldName != null)
	{
		vars.prevWorldName = vars.setPrevWorldName;
		print("set prevWorldName: " + current.sceneName);
		vars.setPrevWorldName = null;
	}

	var validSceneName = false;
	try
	{
		validSceneName = current.sceneName.Length > 0 && current.sceneName != "Temp";
	}
	catch {}

	if (!validSceneName)
	{
		return false;
	}

	vars.worldChanged = (current.sceneName.EndsWith("World")
		|| current.sceneName == "Input Tutorial"
		|| current.sceneName == "Credits")
		&& vars.prevWorldName != current.sceneName;
	if (vars.worldChanged)
	{
		vars.setPrevWorldName = current.sceneName;
	}
}

start
{
	return vars.prevWorldName == "Input Tutorial" && current.sceneName == "Tutorial World";
}

isLoading
{
	return current.sceneName == "Load Screen";
}

reset
{
	return current.sceneName == "Input Tutorial";
}

split
{
	return vars.worldChanged && settings[current.sceneName];
}
