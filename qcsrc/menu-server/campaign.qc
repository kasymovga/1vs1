// CampaignFileLoad(offset, n)
// - Loads campaign level data (up to n entries starting at offset)
//   into the globals
// - Returns the number of entries successfully read
float(float offset, float n) campaign_file_load {
	float fh;
	float lineno;
	float entlen;
	float i;
	string l, a;
	string fn;
	if (n > CAMPAIGN_MAX_ENTRIES)
		n = CAMPAIGN_MAX_ENTRIES;

	campaign_offset = offset;
	campaign_entries = 0;
	campaign_title = NULL;
	fn = strcat("maps/campaign", campaign_name, ".txt");
	fh = fopen(fn, FILE_READ);
	if (fh >= 0) {
		for (lineno = 0; (l = fgets(fh)); ) {
			if (strlen(l) == 0)
				continue; // empty line

			if (substring(l, 0, 11) == "//campaign:")
				campaign_title = substring(l, 11, strlen(l) - 11);

			if (substring(l, 0, 2) == "//")
				continue; // comment

			if (substring(l, 0, 12) == "\"//campaign:")
				campaign_title = substring(l, 12, strlen(l) - 13);

			if (substring(l, 0, 3) == "\"//")
				continue; // comment

			if (lineno >= offset) {
				entlen = tokenize(l); // using insane tokenizer for CSV
				#define CAMPAIGN_GETARG if (i >= entlen) break; a = argv(++i); if (a == ",") a = ""; else ++i
				i = -1; // starts at -1 so I don't need postincrement; that is, i points to BEFORE the current arg!
				CAMPAIGN_GETARG; campaign_gametype[campaign_entries] = str_zone_ifneeded(a);
				CAMPAIGN_GETARG; campaign_mapname[campaign_entries] = str_zone_ifneeded(a);
				CAMPAIGN_GETARG; campaign_bots[campaign_entries] = stof(a);
				CAMPAIGN_GETARG; campaign_botskill[campaign_entries] = stof(a);
				CAMPAIGN_GETARG; campaign_fraglimit[campaign_entries] = stof(a);
				CAMPAIGN_GETARG; campaign_mutators[campaign_entries] = str_zone_ifneeded(a);
				CAMPAIGN_GETARG; campaign_shortdesc[campaign_entries] = str_zone_ifneeded(a);
				CAMPAIGN_GETARG; campaign_longdesc[campaign_entries] = str_zone_ifneeded(strreplace("\\n", "\n", a));
				#undef CAMPAIGN_GETARG
				campaign_entries = campaign_entries + 1;
				if (campaign_entries >= n)
					break;
			}
			lineno = lineno + 1;
		}
		fclose(fh);
	}
	campaign_title = strzone(campaign_title);
	return campaign_entries;
}

void() campaign_file_unload {
	float i;
	if (campaign_title) {
		strunzone(campaign_title);
		for(i = 0; i < CAMPAIGN_MAX_ENTRIES; ++i) {
			str_unzone_ifneeded(campaign_gametype[i]);
			str_unzone_ifneeded(campaign_mapname[i]);
			str_unzone_ifneeded(campaign_mutators[i]);
			str_unzone_ifneeded(campaign_shortdesc[i]);
			str_unzone_ifneeded(campaign_longdesc[i]);
		}
		campaign_entries = 0;
		campaign_title = NULL;
	}
}

void(float n) campaign_setup_cvars_only {
	localcmd("set g_campaign 1\n");
	localcmd("set _campaign_name \""); localcmd(campaign_name); localcmd("\"\n");
	localcmd("set _campaign_index "); localcmd(ftos(campaign_offset + n)); localcmd("\n");
	localcmd(strcat("maxplayers ", ftos(campaign_bots[n] + 1), "\nskill 4\n"));
}

void(float n) campaign_setup {
	campaign_setup_cvars_only(n);
	localcmd("disconnect\n");
	map_info_load_map(campaign_mapname[n]);
}
