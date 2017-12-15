string getZonedTooltipForIdentifier(string s)
{
	string t;
	if(s == "")
		return string_null;
#ifdef MENUQC
	t = db_get(tooltipdb, s);
	if(t == "-")
		return string_null;
	if(t != "")
		return strzone(t);
	t = cvar_description(s);
	if(t != "" && t != "custom cvar")
		return strzone(t);
	dprint("WARNING: no tooltip set for ", s, "\n");
#endif
	return string_null;
}
