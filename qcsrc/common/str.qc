string(string s) str_zone_ifneeded {
	if (s != "")
		return strzone(s);

	return "";
}

void(string s) str_unzone_ifneeded {
	if (s != "")
		strunzone(s);
}

string(string s) str_car {
	float o;
	o = strstrofs(s, " ", 0);
	if(o < 0)
		return s;
	return substring(s, 0, o);
}

string(string s) str_cdr {
	float o;
	o = strstrofs(s, " ", 0);
	if(o < 0)
		return string_null;
	return substring(s, o + 1, strlen(s) - (o + 1));
}
