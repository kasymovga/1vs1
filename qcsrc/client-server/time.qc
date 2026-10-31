string(float hundredths) time_mmssss {
	float minutes;
	string s;
	hundredths = floor(hundredths + 0.5);
	minutes = floor(hundredths / 6000);
	hundredths -= minutes * 6000;
	s = ftos(10000 + hundredths);
	return strcat(ftos(minutes), ":", str_sub(s, 1, 2), ".", str_sub(s, 3, 2));
}
