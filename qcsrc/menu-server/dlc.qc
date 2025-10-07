string(string s) dlc_trimquotes {
	if (substring(s, 0, 1) == "\"")
	if (substring(s, strlen(s) - 1, 1) == "\"")
		s = substring(s, 1, strlen(s) - 2);

	return s;
}

string(string s) dlc_trimcommentary {
	float n = -1;
	float doubleslash = -1;
	float hash = -1;
	float quote = strstrofs(s, "\"", 0);
	while ((n = strstrofs(s, "//", n + 1)) > 0) {
		if (quote < 0 || strstrofs(s, "\"", n) < 0 || quote > n ) {
			doubleslash = n;
			break;
		}
	}
	n = -1;
	while ((n = strstrofs(s, "#", n + 1)) > 0) {
		if (quote < 0 || strstrofs(s, "\"", n) < 0 || quote > n ) {
			hash = n;
			break;
		}
	}
	if (doubleslash > 0)
		s = substring(s, 0, doubleslash);

	if (hash > 0 && (doubleslash < 0 || hash < doubleslash))
		s = substring(s, 0, hash);

	return s;
}

string(string s) dlc_trimspaces {
	string c;
	for (;;) {
		c = substring(s, 0, 1);
		if (c == " " || c == "\t") {
			s = substring (s, 1, -1);
			continue;
		}
		break;
	}
	float n;
	for (;;) {
		n = strlen(s) - 1;
		if (n < 0) break;
		c = substring(s, n, 1);
		if (c == " " || c == "\t") {
			s = substring (s, 0, n);
			continue;
		}
		break;
	}
	return s;
}

float(string s) dlc_findspace {
	float space = strstrofs(s, " ", 0);
	float tab = strstrofs(s, "\t", 0);
	float separator = -1;
	if (space > 0 && tab > 0)
		separator = min(space, tab);
	else if (space > 0)
		separator = space;
	else if (tab > 0)
		separator = tab;

	return separator;
}

