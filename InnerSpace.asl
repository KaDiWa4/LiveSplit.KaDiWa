state("InnerSpace")
{
	string32 sceneName : 0x0144F9D0, 0x48, 0x48;
}

update
{
	try
	{
		return current.sceneName != "Temp";
	}
	catch (Microsoft.CSharp.RuntimeBinder.RuntimeBinderException e)
	{
	    return false;
	}
}

isLoading
{
	return current.sceneName == "Load Screen";
}
