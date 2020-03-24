float(string s) str_width_colors {
	return stringwidth(s, TRUE);
}

float(string s) str_width_nocolors {
	return stringwidth(s, FALSE);
}
