string ScoreString(float pFlags, float pValue)
{
	string valstr;
	float l;

	pValue = floor(pValue + 0.5); // round

	if((pValue == 0) && (pFlags & (SFL_HIDE_ZERO | SFL_RANK | SFL_TIME)))
		valstr = "";
	else if(pFlags & SFL_RANK)
	{
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
	}
	else if(pFlags & SFL_TIME)
		valstr = TIME_ENCODED_TOSTRING(pValue);
	else
		valstr = ftos(pValue);

	return valstr;
}

