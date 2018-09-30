vector colormapPaletteColor(float c, float isPants)
{
	switch(c)
	{
		case  0: return '0.800000 0.800000 0.800000';
		case  1: return '0.600000 0.400000 0.000000';
		case  2: return '0.000000 1.000000 0.501961';
		case  3: return '0.000000 1.000000 0.000000';
		case  4: return '1.000000 0.000000 0.000000';
		case  5: return '0.000000 0.658824 1.000000';
		case  6: return '0.000000 1.000000 1.000000';
		case  7: return '0.501961 1.000000 0.000000';
		case  8: return '0.501961 0.000000 1.000000';
		case  9: return '1.000000 0.000000 1.000000';
		case 10: return '1.000000 0.000000 0.501961';
		case 11: return '0.600000 0.600000 0.600000';
		case 12: return '1.000000 1.000000 0.000000';
		case 13: return '0.000000 0.313725 1.000000';
		case 14: return '1.000000 0.501961 0.000000';
		case 15:
			if(isPants)
				return
					  '1 0 0' * (0.502 + 0.498 * sin(time / 2.7182818285 + 0.0000000000))
					+ '0 1 0' * (0.502 + 0.498 * sin(time / 2.7182818285 + 2.0943951024))
					+ '0 0 1' * (0.502 + 0.498 * sin(time / 2.7182818285 + 4.1887902048));
			else
				return
					  '1 0 0' * (0.502 + 0.498 * sin(time / 3.1415926536 + 5.2359877560))
					+ '0 1 0' * (0.502 + 0.498 * sin(time / 3.1415926536 + 3.1415926536))
					+ '0 0 1' * (0.502 + 0.498 * sin(time / 3.1415926536 + 1.0471975512));
		default: return '0.000 0.000 0.000';
	}
}

float textLengthUpToWidth(string theText, float maxWidth, textLengthUpToWidth_widthFunction_t w)
{
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
	do
	{
		middle = floor((left + right) / 2);
		if(w(substring(theText, 0, middle)) <= maxWidth)
			left = middle;
		else
			right = middle;
	}
	while(left < right - 1);

	if(ICanHasKallerz)
	{
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

string getWrappedLine(float w, textLengthUpToWidth_widthFunction_t tw)
{
	float cantake;
	float take;
	string s;

	s = getWrappedLine_remaining;

	cantake = textLengthUpToWidth(s, w, tw);
	if(cantake > 0 && cantake < strlen(s))
	{
		take = cantake - 1;
		while(take > 0 && substring(s, take, 1) != " ")
			--take;
		if(take == 0)
		{
			getWrappedLine_remaining = substring(s, cantake, strlen(s) - cantake);
			if(getWrappedLine_remaining == "")
				getWrappedLine_remaining = string_null;
			return substring(s, 0, cantake);
		}
		else
		{
			getWrappedLine_remaining = substring(s, take + 1, strlen(s) - take);
			if(getWrappedLine_remaining == "")
				getWrappedLine_remaining = string_null;
			return substring(s, 0, take);
		}
	}
	else
	{
		getWrappedLine_remaining = string_null;
		return s;
	}
}

// converts a number to a string with the indicated number of decimals
// works for up to 10 decimals!
string ftos_decimals(float number, float decimals)
{
	string result;
	string tmp;
	float len;

	// if negative, cut off the sign first
	if(number < 0)
		return strcat("-", ftos_decimals(-number, decimals));
	// it now is always positive!

	// 3.516 -> 352
	number = floor(number * pow(10, decimals) + 0.5);

	// 352 -> "352"
	result = ftos(number);
	len = strlen(result);
	// does it have a decimal point (should not happen)? If there is one, it is always at len-7)
		// if ftos had messed it up, which should never happen: "34278.000000"
	if(len >= 7)
		if(substring(result, len - 7, 1) == ".")
		{
			dprint("ftos(integer) has comma? Can't be. Affected result: ", result, "\n");
			result = substring(result, 0, len - 7);
			len -= 7;
		}
		// "34278"
	if(decimals == 0)
		return result; // don't insert a point for zero decimals
	// is it too short? If yes, insert leading zeroes
	if(len <= decimals)
	{
		result = strcat(substring("0000000000", 0, decimals - len + 1), result);
		len = decimals + 1;
	}
	// and now... INSERT THE POINT!
	tmp = substring(result, len - decimals, decimals);
	result = strcat(substring(result, 0, len - decimals), ".", tmp);
	return result;
}

string GametypeNameFromType(float g)
{
	if      (g == GAME_DEATHMATCH) return "dm";
	else if (g == GAME_TEAM_DEATHMATCH) return "tdm";
	else if (g == GAME_DOMINATION) return "dom";
	else if (g == GAME_CTF) return "ctf";
	else if (g == GAME_CATF) return "catf";
	else if (g == GAME_RUNEMATCH) return "rune";
	else if (g == GAME_KEYHUNT) return "kh";
	else if (g == GAME_ONSLAUGHT) return "ons";
	else if (g == GAME_RACE) return "rc";
	else if (g == GAME_NEXBALL) return "nexball";
	else if (g == GAME_CTS) return "cts";
	else if (g == GAME_FREEZETAG) return "ft";
	else if (g == GAME_CLANARENA) return "ca";
	else if (g == GAME_CONQUEST) return "conq";
	else if (g == GAME_SURVIVE) return "surv";
	return "dm";
}

// Multiline text file buffers
float buf_load(string pFilename)
{
	float buf, fh, i;
	string l;
	buf = buf_create();
	if(buf < 0)
		return -1;
	fh = fopen(pFilename, FILE_READ);
	if(fh < 0)
		return buf;
	i = 0;
	while((l = fgets(fh)))
	{
		bufstr_set(buf, i, l);
		++i;
	}
	fclose(fh);
	return buf;
}

string db_get(float db, string pKey)
{
	float h;
	h = mod(crc16(FALSE, pKey), DB_BUCKETS);
	return uri_unescape(infoget(bufstr_get(db, h), pKey));
}

void db_put(float db, string pKey, string pValue)
{
	float h;
	h = mod(crc16(FALSE, pKey), DB_BUCKETS);
	bufstr_set(db, h, infoadd(bufstr_get(db, h), pKey, uri_escape(pValue)));
}

float db_create()
{
	return buf_create();
}

float db_load(string pFilename)
{
	float db, fh, i, j, n;
	string l;
	db = buf_create();
	if(db < 0)
		return -1;
	fh = fopen(pFilename, FILE_READ);
	if(fh < 0)
		return db;
	if(stof(fgets(fh)) == DB_BUCKETS)
	{
		i = 0;
		while((l = fgets(fh)))
		{
			if(l != "")
				bufstr_set(db, i, l);
			++i;
		}
	}
	else
	{
		// different count of buckets?
		// need to reorganize the database then (SLOW)
		while((l = fgets(fh)))
		{
			n = tokenizebyseparator(l, "\\");
			for(j = 2; j < n; j += 2)
				db_put(db, argv(j-1), uri_unescape(argv(j)));
		}
	}
	fclose(fh);
	return db;
}

void db_close(float db)
{
	buf_del(db);
}

/*
 *  Operator overloads
 */
string operator+(string s, float f) {
    return s + ftos(f);
}

string operator+(float f, string s) {
    return ftos(f) + s;
}

string operator+(string s, vector v) {
    return s + vtos(v);
}

string operator+(vector v, string s) {
    return vtos(v) + s;
}
