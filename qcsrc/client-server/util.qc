vector cross(vector a, vector b)
{
	return
		'1 0 0' * (a_y * b_z - a_z * b_y)
	+	'0 1 0' * (a_z * b_x - a_x * b_z)
	+	'0 0 1' * (a_x * b_y - a_y * b_x);
}

float mod(float a, float b) { return a - (floor(a / b) * b); }

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

float isGametypeInFilter(float gt, float tp, string pattern)
{
	string subpattern, subpattern2, subpattern3;
	subpattern = strcat(",", gametype_name(gt), ",");
	if(tp)
		subpattern2 = ",teams,";
	else
		subpattern2 = ",noteams,";
	if(gt == GAME_RACE || gt == GAME_CTS)
		subpattern3 = ",race,";
	else
		subpattern3 = string_null;

	if(substring(pattern, 0, 1) == "-")
	{
		pattern = substring(pattern, 1, strlen(pattern) - 1);
		if(strstrofs(strcat(",", pattern, ","), subpattern, 0) >= 0)
			return 0;
		if(strstrofs(strcat(",", pattern, ","), subpattern2, 0) >= 0)
			return 0;
		if(subpattern3 && strstrofs(strcat(",", pattern, ","), subpattern3, 0) >= 0)
			return 0;
	}
	else
	{
		if(substring(pattern, 0, 1) == "+")
			pattern = substring(pattern, 1, strlen(pattern) - 1);
		if(strstrofs(strcat(",", pattern, ","), subpattern, 0) < 0)
		if(strstrofs(strcat(",", pattern, ","), subpattern2, 0) < 0)
		if((!subpattern3) || strstrofs(strcat(",", pattern, ","), subpattern3, 0) < 0)
			return 0;
	}
	return 1;
}

string mmssss(float hundredths)
{
	float minutes;
	string s;
	hundredths = floor(hundredths + 0.5);
	minutes = floor(hundredths / 6000);
	hundredths -= minutes * 6000;
	s = ftos(10000 + hundredths);
	return strcat(ftos(minutes), ":", substring(s, 1, 2), ".", substring(s, 3, 2));
}

void compressShortVector_init()
{
	float l, f, i;
	l = 1;
	f = pow(2, 1/8);
	for(i = 0; i < 128; ++i)
	{
		lengthLogTable[i] = l;
		l *= f;
	}
}

// Databases (hash tables)
void db_save(float db, string pFilename)
{
	float fh, i, n;
	fh = fopen(pFilename, FILE_WRITE);
	if(fh < 0)
	{
		print(strcat("^1Can't write DB to ", pFilename));
		return;
	}
	n = buf_getsize(db);
	fputs(fh, strcat(ftos(DB_BUCKETS), "\n"));
	for(i = 0; i < n; ++i)
		fputs(fh, strcat(bufstr_get(db, i), "\n"));
	fclose(fh);
}

void db_dump(float db, string pFilename)
{
	float fh, i, j, n, m;
	fh = fopen(pFilename, FILE_WRITE);
	if(fh < 0)
		error(strcat("Can't dump DB to ", pFilename));
	n = buf_getsize(db);
	fputs(fh, "0\n");
	for(i = 0; i < n; ++i)
	{
		m = tokenizebyseparator(bufstr_get(db, i), "\\");
		for(j = 2; j < m; j += 2)
			fputs(fh, strcat("\\", argv(j-1), "\\", argv(j), "\n"));
	}
	fclose(fh);
}

void buf_save(float buf, string pFilename)
{
	float fh, i, n;
	fh = fopen(pFilename, FILE_WRITE);
	if(fh < 0)
		error(strcat("Can't write buf to ", pFilename));
	n = buf_getsize(buf);
	for(i = 0; i < n; ++i)
		fputs(fh, strcat(bufstr_get(buf, i), "\n"));
	fclose(fh);
}

void get_mi_min_max(float mode)
{
	vector mi, ma;

	if(mi_shortname)
		strunzone(mi_shortname);
	mi_shortname = mapname;
	if(!strcasecmp(substring(mi_shortname, 0, 5), "maps/"))
		mi_shortname = substring(mi_shortname, 5, strlen(mi_shortname) - 5);
	if(!strcasecmp(substring(mi_shortname, strlen(mi_shortname) - 4, 4), ".bsp"))
		mi_shortname = substring(mi_shortname, 0, strlen(mi_shortname) - 4);
	mi_shortname = strzone(mi_shortname);

#ifdef CSQC
	mi = world.mins;
	ma = world.maxs;
#else
	mi = world.absmin;
	ma = world.absmax;
#endif

	mi_min = mi;
	mi_max = ma;
	// not specified
	if(mode)
	{
		// be clever
		tracebox('1 0 0' * mi_x,
				 '0 1 0' * mi_y + '0 0 1' * mi_z,
				 '0 1 0' * ma_y + '0 0 1' * ma_z,
				 '1 0 0' * ma_x,
				 MOVE_WORLDONLY,
				 world);
		if(!trace_startsolid)
			mi_min_x = trace_endpos_x;

		tracebox('0 1 0' * mi_y,
				 '1 0 0' * mi_x + '0 0 1' * mi_z,
				 '1 0 0' * ma_x + '0 0 1' * ma_z,
				 '0 1 0' * ma_y,
				 MOVE_WORLDONLY,
				 world);
		if(!trace_startsolid)
			mi_min_y = trace_endpos_y;

		tracebox('0 0 1' * mi_z,
				 '1 0 0' * mi_x + '0 1 0' * mi_y,
				 '1 0 0' * ma_x + '0 1 0' * ma_y,
				 '0 0 1' * ma_z,
				 MOVE_WORLDONLY,
				 world);
		if(!trace_startsolid)
			mi_min_z = trace_endpos_z;

		tracebox('1 0 0' * ma_x,
				 '0 1 0' * mi_y + '0 0 1' * mi_z,
				 '0 1 0' * ma_y + '0 0 1' * ma_z,
				 '1 0 0' * mi_x,
				 MOVE_WORLDONLY,
				 world);
		if(!trace_startsolid)
			mi_max_x = trace_endpos_x;

		tracebox('0 1 0' * ma_y,
				 '1 0 0' * mi_x + '0 0 1' * mi_z,
				 '1 0 0' * ma_x + '0 0 1' * ma_z,
				 '0 1 0' * mi_y,
				 MOVE_WORLDONLY,
				 world);
		if(!trace_startsolid)
			mi_max_y = trace_endpos_y;

		tracebox('0 0 1' * ma_z,
				 '1 0 0' * mi_x + '0 1 0' * mi_y,
				 '1 0 0' * ma_x + '0 1 0' * ma_y,
				 '0 0 1' * mi_z,
				 MOVE_WORLDONLY,
				 world);
		if(!trace_startsolid)
			mi_max_z = trace_endpos_z;
	}
}

float almost_equals(float a, float b)
{
	float eps;
	eps = (max(a, -a) + max(b, -b)) * 0.001;
	if(a - b < eps && b - a < eps)
		return TRUE;
	return FALSE;
}

// requires that m2>m1 in all coordinates, and that m4>m3
float boxesoverlap(vector m1, vector m2, vector m3, vector m4) {return m2_x >= m3_x && m1_x <= m4_x && m2_y >= m3_y && m1_y <= m4_y && m2_z >= m3_z && m1_z <= m4_z;};
