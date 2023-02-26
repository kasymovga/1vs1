string(string s, float depth) str_shuffle_words_recursive {
	if (depth <= 0) return s;
	float splitpos;
	splitpos = (strlen(s) * (0.25 + random() * 0.5));
	float spacepos = strstrofs(s, " ", splitpos);
	if (spacepos < 0 && splitpos > 0) {
		splitpos = floor(splitpos / 3);
		spacepos = strstrofs(s, " ", splitpos);
	}
	if (spacepos < 0) return s;
	string s1 = str_shuffle_words_recursive(substring(s, 0, spacepos), depth - 1);
	string s2 = str_shuffle_words_recursive(substring(s, spacepos + 1, -1), depth - 1);
	if (random() < 0.5)
		return strcat(s1, " ", s2);

	return strcat(s2, " ", s1);
}

string(string s) str_shuffle_words {
	float i;
	for (i = 0; i < 10; i++) s = str_shuffle_words_recursive(s, 10);
	return s;
}
