string(string theText, float maxWidth, str_length_up_to_width_width_function_t tw) str_shorten_to_width {
	if(tw(theText) <= maxWidth)
		return theText;
	else
		return strcat(substring(theText, 0, str_length_up_to_width(theText, maxWidth - tw("..."), tw)), "...");
}

float(string s) str_width_colors {
	return stringwidth(s, TRUE);
}

float(string s) str_width_nocolors {
	return stringwidth(s, FALSE);
}

string(string s) str_color_translate_rgb {
	if (CVAR(cl_stripcolorcodes))
		return strdecolorize(s);
	else
		return s;
}

