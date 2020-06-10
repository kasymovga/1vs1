void(void) race_read {
	float b;
	b = ReadByte();
	float i;
	switch(b) {
		case RACE_NET_CHECKPOINT_HIT_QUALIFYING:
			race_checkpoint = ReadByte();
			race_time = net_read_int24();
			race_previousbesttime = net_read_int24();
			if(race_previousbestname)
				strunzone(race_previousbestname);

			race_previousbestname = strzone(str_color_translate_rgb(ReadString()));
			race_checkpointtime = max(time, 0.001);
			if(race_checkpoint == 0 || race_checkpoint == 254) {
				race_penaltyaccumulator = 0;
				race_laptime = max(time, 0.001); // valid
			}
			break;
		case RACE_NET_CHECKPOINT_CLEAR:
			race_laptime = 0;
			race_checkpointtime = 0;
			break;
		case RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING:
			race_laptime = ReadCoord();
			race_checkpointtime = -99999;
			// fall through
		case RACE_NET_CHECKPOINT_NEXT_QUALIFYING:
			race_nextcheckpoint = ReadByte();
			race_nextbesttime = net_read_int24();
			if(race_nextbestname)
				strunzone(race_nextbestname);

			race_nextbestname = strzone(str_color_translate_rgb(ReadString()));
			break;
		case RACE_NET_CHECKPOINT_HIT_RACE:
			race_mycheckpoint = ReadByte();
			race_mycheckpointtime = time;
			race_mycheckpointdelta = net_read_int24();
			race_mycheckpointlapsdelta = ReadByte();
			if(race_mycheckpointlapsdelta >= 128)
				race_mycheckpointlapsdelta -= 256;

			if(race_mycheckpointenemy)
				strunzone(race_mycheckpointenemy);

			race_mycheckpointenemy = strzone(str_color_translate_rgb(ReadString()));
			break;
		case RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT:
			race_othercheckpoint = ReadByte();
			race_othercheckpointtime = time;
			race_othercheckpointdelta = net_read_int24();
			race_othercheckpointlapsdelta = ReadByte();
			if(race_othercheckpointlapsdelta >= 128)
				race_othercheckpointlapsdelta -= 256;

			if(race_othercheckpointenemy)
				strunzone(race_othercheckpointenemy);

			race_othercheckpointenemy = strzone(str_color_translate_rgb(ReadString()));
			break;
		case RACE_NET_PENALTY_RACE:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			//race_penaltyaccumulator += race_penaltytime;
			if(race_penaltyreason)
				strunzone(race_penaltyreason);

			race_penaltyreason = strzone(ReadString());
			break;
		case RACE_NET_PENALTY_QUALIFYING:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			race_penaltyaccumulator += race_penaltytime;
			if(race_penaltyreason)
				strunzone(race_penaltyreason);

			race_penaltyreason = strzone(ReadString());
			break;
		case RACE_NET_RECORDS_TABLE:
			for (i = 0; i < 10; i++) {
				race_records_time[i] = ReadCoord();
				race_records_name[i] = str_zone_ifneeded(ReadString());
			}
			break;
	}
}

string(float cp, float mytime, float histime, float lapdelta, string hisname) race_checkpoint_string {
	string col;
	string timestr;
	string cpname;
	string lapstr;
	lapstr = "";

	if(histime == 0) // goal hit
	{
		if(mytime > 0)
		{
			timestr = strcat("+", str_float_decimals(+mytime, TIME_DECIMALS));
			col = "^1";
		}
		else if(mytime == 0)
		{
			timestr = "+0.0";
			col = "^3";
		}
		else
		{
			timestr = strcat("-", str_float_decimals(-mytime, TIME_DECIMALS));
			col = "^2";
		}

		if(lapdelta > 0)
		{
			lapstr = strcat(" (-", ftos(lapdelta), "L)");
			col = "^2";
		}
		else if(lapdelta < 0)
		{
			lapstr = strcat(" (+", ftos(-lapdelta), "L)");
			col = "^1";
		}
	}
	else if(histime > 0) // anticipation
	{
		if(mytime >= histime)
			timestr = strcat("+", str_float_decimals(mytime - histime, TIME_DECIMALS));
		else
			timestr = TIME_ENCODED_TOSTRING(TIME_ENCODE(histime));
		col = "^3";
	}
	else
		col = "^7";

	if(cp == 254)
		cpname = "Start line";
	else if(cp == 255)
		cpname = "Finish line";
	else if(cp)
		cpname = strcat("Intermediate ", ftos(cp));
	else
		cpname = "Finish line";

	if(histime < 0)
		return strcat(col, cpname);
	else if(hisname == "")
		return strcat(col, cpname, " (", timestr, ")");
	else
		return strcat(col, cpname, " (", timestr, " ", strcat(hisname, col, lapstr), ")");
}

