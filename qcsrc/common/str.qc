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
		return NULL;
	return substring(s, o + 1, strlen(s) - (o + 1));
}

string(float number, float decimals) str_float_decimals {
	string result;
	string tmp;
	float len;
	// if negative, cut off the sign first
	if(number < 0)
		return strcat("-", str_float_decimals(-number, decimals));

	number = floor(number * pow(10, decimals) + 0.5);
	result = ftos(number);
	len = strlen(result);
	if(len >= 7)
		if(substring(result, len - 7, 1) == ".")
		{
			result = substring(result, 0, len - 7);
			len -= 7;
		}
	if(decimals == 0)
		return result; // don't insert a point for zero decimals

	if(len <= decimals) {
		result = strcat(substring("0000000000", 0, decimals - len + 1), result);
		len = decimals + 1;
	}
	tmp = substring(result, len - decimals, decimals);
	result = strcat(substring(result, 0, len - decimals), ".", tmp);
	return result;
}

float(string theText, float maxWidth, str_length_up_to_width_width_function_t w) str_length_up_to_width {
	float ICanHasKallerz;
	// detect color codes support in the width function
	ICanHasKallerz = (w("^7") == 0);
	// STOP.
	// The following function is SLOW.
	// For your safety and for the protection of those around you...
	// DO NOT CALL THIS AT HOME.
	// No really, don't.
	if(w(theText) <= maxWidth)
		return strlen(theText); // yeah!

	// binary search for right place to cut string
	float ch;
	float left, right, middle; // this always works
	left = 0;
	right = strlen(theText); // this always fails
	do {
		middle = floor((left + right) / 2);
		if(w(substring(theText, 0, middle)) <= maxWidth)
			left = middle;
		else
			right = middle;
	}
	while(left < right - 1);
	if(ICanHasKallerz) {
		// NOTE: when color codes are involved, this binary search is,
		// mathematically, BROKEN. However, it is obviously guaranteed to
		// terminate, as the range still halves each time - but nevertheless, it is
		// guaranteed that it finds ONE valid cutoff place (where "left" is in
		// range, and "right" is outside).

		// terencehill: the following code detects truncated ^xrgb tags (e.g. ^x or ^x4)
		// and decrease left on the basis of the chars detected of the truncated tag
		// Even if the ^xrgb tag is not complete/correct, left is decreased
		// (sometimes too much but with a correct result)
		// it fixes also ^[0-9]
		while(left >= 1 && substring(theText, left-1, 1) == "^")
			left-=1;

		if (left >= 2 && substring(theText, left-2, 2) == "^x") // ^x/
			left-=2;
		else if (left >= 3 && substring(theText, left-3, 2) == "^x")
			{
				ch = str2chr(theText, left-1);
				if( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') ) // ^xr/
					left-=3;
			}
		else if (left >= 4 && substring(theText, left-4, 2) == "^x")
			{
				ch = str2chr(theText, left-2);
				if ( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') )
				{
					ch = str2chr(theText, left-1);
					if ( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') ) // ^xrg/
						left-=4;
				}
			}
	}
	return left;
}

string(float w, str_length_up_to_width_width_function_t tw) str_wrapped_line {
	float cantake;
	float take;
	string s;
	s = str_wrapped_line_remaining;
	cantake = str_length_up_to_width(s, w, tw);
	if(cantake > 0 && cantake < strlen(s)) {
		take = cantake - 1;
		while(take > 0 && substring(s, take, 1) != " ")
			--take;

		if(take == 0) {
			str_wrapped_line_remaining = substring(s, cantake, strlen(s) - cantake);
			if(str_wrapped_line_remaining == "")
				str_wrapped_line_remaining = NULL;

			return substring(s, 0, cantake);
		} else {
			str_wrapped_line_remaining = substring(s, take + 1, strlen(s) - take);
			if(str_wrapped_line_remaining == "")
				str_wrapped_line_remaining = NULL;

			return substring(s, 0, take);
		}
	} else {
		str_wrapped_line_remaining = NULL;
		return s;
	}
}
