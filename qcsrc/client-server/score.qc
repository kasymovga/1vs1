string(float pFlags, float pValue) score_string {
	string valstr;
	float l;
	pValue = floor(pValue + 0.5); // round
	if((pValue == 0) && (pFlags & (SCORE_FLAG_HIDE_ZERO | SCORE_FLAG_RANK | SCORE_FLAG_TIME)))
		valstr = "";
	else if(pFlags & SCORE_FLAG_RANK) {
		valstr = ftos(pValue);
		l = strlen(valstr);
		if((l >= 2) && (substring(valstr, l - 2, 1) == "1"))
			valstr = strcat(valstr, "th");
		else if(substring(valstr, l - 1, 1) == "1")
			valstr = strcat(valstr, "st");
		else if(substring(valstr, l - 1, 1) == "2")
			valstr = strcat(valstr, "nd");
		else if(substring(valstr, l - 1, 1) == "3")
			valstr = strcat(valstr, "rd");
		else
			valstr = strcat(valstr, "th");
	} else if(pFlags & SCORE_FLAG_TIME)
		valstr = TIME_ENCODED_TOSTRING(pValue);
	else
		valstr = ftos(pValue);

	return valstr;
}
