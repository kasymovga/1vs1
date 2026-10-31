float(float gt, float tp, string pattern) game_type_filter {
	string subpattern, subpattern2, subpattern3;
	subpattern = strcat(",", game_type_name(gt), ",");
	if(tp)
		subpattern2 = ",teams,";
	else
		subpattern2 = ",noteams,";

	if(gt == GAME_TYPE_RACE || gt == GAME_TYPE_CTS)
		subpattern3 = ",race,";
	else
		subpattern3 = NULL;

	if(str_sub(pattern, 0, 1) == "-") {
		pattern = str_sub(pattern, 1, strlen(pattern) - 1);
		if(strstrofs(strcat(",", pattern, ","), subpattern, 0) >= 0)
			return 0;
		if(strstrofs(strcat(",", pattern, ","), subpattern2, 0) >= 0)
			return 0;
		if(subpattern3 && strstrofs(strcat(",", pattern, ","), subpattern3, 0) >= 0)
			return 0;
	} else {
		if(str_sub(pattern, 0, 1) == "+")
			pattern = str_sub(pattern, 1, strlen(pattern) - 1);
		if(strstrofs(strcat(",", pattern, ","), subpattern, 0) < 0)
		if(strstrofs(strcat(",", pattern, ","), subpattern2, 0) < 0)
		if((!subpattern3) || strstrofs(strcat(",", pattern, ","), subpattern3, 0) < 0)
			return 0;
	}
	return 1;
}
