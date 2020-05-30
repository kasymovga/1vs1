void(void) race_read {
	float b;
	b = ReadByte();
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
	}
}


