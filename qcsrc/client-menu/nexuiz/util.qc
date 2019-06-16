float tooltipdb;
void loadTooltips()
{
	tooltipdb = db_load("tooltips.db");
}
void unloadTooltips()
{
	db_close(tooltipdb);
	tooltipdb = -1;
}

string getZonedTooltipForIdentifier(string s)
{
	string t;
	if(s == "")
		return string_null;

	if (tooltipdb >= 0) {
		t = db_get(tooltipdb, s);
		if(t == "-")
			return string_null;
		if(t != "")
			return strzone(t);
	}
#ifndef CSQC
	t = cvar_description(s);
	if(t != "" && t != "custom cvar")
		return strzone(t);
#endif
	return string_null;
}
