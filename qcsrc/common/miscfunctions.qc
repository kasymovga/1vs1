string zone_ifneeded(string s) {
	if (s != "")
		return strzone(s);

	return "";
}

string cvar_string_zone_ifneeded(string cvar_name) {
	return zone_ifneeded(cvar_string(cvar_name));
}

void unzone_ifneeded(string s) {
	if (s != "")
		strunzone(s);
}

float fexist(string path) {
	float f = fopen(path, FILE_READ);
	if (f < 0)
		return FALSE;

	fclose(f);
	return TRUE;
}
