// CampaignFileLoad(offset, n)
// - Loads campaign level data (up to n entries starting at offset)
//   into the globals
// - Returns the number of entries successfully read
void(string gt, string map, float bots, float skill, float frag, string settings, string descr, string descr_long) campaign_entry {
	if (campaign_entries >= CAMPAIGN_MAX_ENTRIES) return;
	campaign_gametype[campaign_entries] = gt;
	campaign_mapname[campaign_entries] = map;
	campaign_bots[campaign_entries] = bots;
	campaign_botskill[campaign_entries] = skill;
	campaign_fraglimit[campaign_entries] = frag;
	campaign_mutators[campaign_entries] = settings;
	campaign_shortdesc[campaign_entries] = descr;
	campaign_longdesc[campaign_entries] = descr_long;
	campaign_entries++;
}

float(float offset, float n) campaign_file_load {
	float fh;
	float lineno;
	float entlen;
	float i;
	string l, a;
	string fn;
	if (n > CAMPAIGN_MAX_ENTRIES)
		n = CAMPAIGN_MAX_ENTRIES;

	campaign_entries = 0;
	campaign_title = NULL;
	if (campaign_name == "rexclassic") {
		campaign_title = "Rexuiz Classic Campaign";
		campaign_entry("single", "e1m1", 0, 1, 0, "" , "Episode 1", "First episode from the original Quake(r) from id Software");
		campaign_entry("single", "e2m1", 0, 1, 0, "" , "Episode 2", "Second episode from the original Quake(r) from id Software");
		campaign_entry("single", "e3m1", 0, 1, 0, "" , "Episode 3", "Third episode from the original Quake(r) from id Software");
		campaign_entry("single", "e4m1", 0, 1, 0, "" , "Episode 4", "Fourth episode from the original Quake(r) from id Software");
		campaign_entry("single", "e5m1", 0, 1, 0, "" , "Final", "Final level from the original Quake(r) from id Software");
	} else if (campaign_name == "rexuiz") {
		campaign_title = "Rexuiz Multiplayer Training Campaign";
		campaign_entry("coop", "rextutor", 0, 1, 0, "", "Basic tutorial", "Welcome to Rexuiz!\n\nYou'll start off with this simple guided tutorial, which will teach you some very basic things about Rexuiz which might not seem obvious at first.\n");
		campaign_entry("dm", "runningman_1on1remix", 1, 1, 10, "", "DM: Running Man (1on1)", "Welcome to the Rexuiz Campaign!\n\nFirst of all, you're going to learn the controls of the game by playing an easy 1on1 deathmatch against a single unskilled bot.\n\nFirst one to kill the other 10 times wins.");
		campaign_entry("dm", "darkzone", 2, 2, 15, "", "DM: Q1DM6 Remake", "On this remake of a beloved level from the original Quake(r) from id Software, you'll face two bots on a somewhat higher skill level.\n\n15 frags will make you a winner here.");
		campaign_entry("dm", "desertfactory", 3, 3, 20, "", "DM: Desert Factory", "You're fighting three enemies in a deserted factory. Watch out for the hot pipes, as they can kill you.\n\nThe game ends once someone, hopefully you, will have 20 frags.");
		campaign_entry("dm", "soylent", 1, 4, 20, "", "DM: Soylent Space", "This time, you will face a single bot on an interesting space arena that allows many movement tricks. Try to learn these tricks so you can find your enemy faster.\n\nYou win once you have 20 frags.");
		campaign_entry("dm", "skyway", 3, 5, 15, "g_profile minsta", "SPECIAL: Skyway", "MinstaGib means that everyone is equipped with a single weapon that both kills with one shot, and can be used for jumping like the Laser can.\n\nLearn using it to fight off the three enemies that somehow have arrived here too!\n\nThe frag limit is 15.");
		campaign_entry("dm", "starship", 4, 6, 15, "g_akimbo_weapons all", "SPECIAL: Starship", "Fight four bots in a starship especially built for fighting inside.");
		campaign_entry("tdm", "toxic", 3, 6, 20, "", "TDM: Toxic", "In Team Deathmatch, there are two teams fighting each other. The frags of each team are added up, and the first team reaching 20 frags wins.\n\nMake your team this winning team!");
		campaign_entry("tdm", "aggressor", 3, 7, 20, "", "TDM: Aggressor", "Now that you are getting the hang of team deathmatch, let's increase the skill of the bots.\n\nTry to keep them from fragging you!");
		campaign_entry("tdm", "downer", 5, 7, 30, "", "TDM: Downer", "A relatively small map, and more bots, may make this interesting.\n\nWill the adrenaline make you stronger or weaker?");
		campaign_entry("tdm", "warfare", 3, 7, 30, "", "TDM: Warfare", "Greetings to Orbb, who was on this map before you!\n\nFor some contrast, you're now facing only few bots on a larger map. You should know what to do now.\n\nOf course, always avoid hitting team mates, as that damage reflects back to you.");
		campaign_entry("dm", "strength", 4, 8, 20, "g_start_weapon_fireball 1; g_start_weapon_laser 0; g_start_weapon_shotgun 0; g_use_ammunition 0; g_pickup_weapons 0", "SPECIAL: Strength", "Time to Burn");
		campaign_entry("kh", "stormkeep2", 5, 8, 500, "g_kh_teams_override 2", "KH: Stormkeep 2", "In Key Hunt, your goal is to collect the keys from the other teams. You must bring all keys together to get 100 points, and the game will end at 500.");
		campaign_entry("kh", "aneurysm", 5, 8, 600, "g_kh_teams_override 3", "KH: Aneurysm", "On this industrial arena, you are fighting two other teams. As before, you must bring all keys together, for 200 points this time. The total you have to reach is 600.");
		campaign_entry("kh", "bleach", 8, 8, 1000, "g_kh_teams_override 3", "KH: Bleach", "Three Teams Eight Bots.\n\nDo your best.\n\nOver.");
		campaign_entry("kh", "dieselpower", 3, 8, 500, "g_kh_teams_override 2", "KH: Diesel Power", "A large map, and just two bots per team, 4 total. You'll be running around the map all the time, so learn doing it fast.\n\nBy the way, Key Hunt can be played online on quite some servers. You should be ready for online KH play after this match.");
		campaign_entry("dm", "silvercity", 5, 9, 30, "g_profile minsta", "SPECIAL: SilverCity", "You now know MinstaGib...");
		campaign_entry("ctf", "basementctf", 1, 9, 100, "", "CTF: Basement", "Welcome to the Capture The Flag game mode. Here, you are supposed to take the enemy flag, and bring it back to yours.\n\nAlso, you have to prevent the enemy from doing the same, as you can only capture his flag when your flag is still at your base.\n\nLet's start out easy, with a single bot in the enemy team. 100 points win.");
		campaign_entry("ctf", "runningmanctf", 3, 9, 100, "", "CTF: Running Man", "Now that you have played a simple CTF match, let's try one with team mates.\n\nDo not shoot your team mate, and let him protect you while you carry the flag back home.");
		campaign_entry("ctf", "bloodprisonctf", 5, 9, 150, "", "CTF: Blood Prison", "Let's try the same with a total of 6 players.");
		campaign_entry("ctf", "accident", 5, 9, 100, "", "CTF: Accident", "Enough of the CTF training arenas - you can now play on the real thing, namely, this industrial CTF level which you can find on many online servers too. Just remember that this map is called 'accident'.");
		campaign_entry("dm", "evilspace", 3, 10, 9, "g_start_weapon_shotgun 0; g_pickup_items 0", "SPECIAL: [evilspace]", "All you get is a Laser.\n\nWell, I think you know how to use it to push the bots off this map into the deadly void...");
		campaign_entry("dom", "basement", 1, 10, 70, "", "DOM: Basement", "Domination: take control points so they show the color of your team, and make the enemies not take yours. Points are awarded for holding a control point.\n\n70 points win.");
		campaign_entry("dom", "runningman", 3, 10, 100, "", "DOM: Running Man", "This time it's a bigger map and you get a team mate to help you capture the control points.\n\n3 bots, and 100 points to win.");
		campaign_entry("dom", "slimepit", 5, 11, 100, "", "DOM: The Slime Pit", "An old, rusty industrial arena on which you have to watch out for slime...\n\nNote: while trying to capture one control point after another, you should keep an eye on your already captured control points, and defend them from incoming enemies.");
		campaign_entry("dom", "ruiner", 5, 12, 100, "", "DOM: RUINER", "You got through The Slime Pit, go wash off that goo and try one last round of Domination here.\n\nYou may want to enable reflections in the Effects menu, but don't get carried away by them, as there still are control points to worry about...");
		campaign_entry("ctf", "eggandbacon", 7, 13, 200, "", "SPECIAL: Egg & Bacon", "An arena especially for spamming around with all the weapons. Enjoy it, and when you had enough of it, bring the enemy flag home...\n\nYou will notice some odd weapons here that haven't appeared before, by the way. Learn using them.");
		campaign_entry("race", "racetrack", 0, 0, 3600, "", "Race: Racetrack", "Race is about running as fast as possible on the map, by jumping at the right times, and using your weapons to gain more speed.\n\nOn this map, you have to finish a lap in 36.0 seconds to proceed. The mortar which you will find behind you may be an useful tool for this.");
		campaign_entry("dm", "final_rage", 3, 14, 20, "g_start_weapon_rocketlauncher 1; g_start_weapon_laser 0; g_start_weapon_shotgun 0; g_use_ammunition 0; g_pickup_weapons 0", "SPECIAL: Final rage", "Missiles... try playing with them, to let them blow up directly in the face of your enemies.\n\nThe final is near...");
		campaign_entry("dm", "reslimed", 2, 15, 9, "", "DM: Slimepit Revisited", "It is crucial to actually dodge rockets here. Also, there are traps on this map that you can activate to hurt your opponents - find then!");
		campaign_entry("dm", "bluesky", 3, 16, 9, "", "DM: Blue Sky", "And the sky is the limit... enjoy the view and try to keep alive! Your 3 enemies will try to hit you using the Nex and other weapons suitable for long distances, so never stop moving!");
		campaign_entry("dm", "farewell", 4, 17, 9, "", "DM: Farewell", "Show your enemies no mercy in this medieval arena, as they certainly will have none on you!\n\nThis is the last level before the final.");
		campaign_entry("dm", "bloodprison", 5, 20, 9, "", "DM: Blood Prison", "THE FINAL\n\nUse all you have learned so far and win the campaign if you can!");
	} else if (campaign_name == "rexsurvival") {
		campaign_title = "Rexuiz Survival Campaign";
		campaign_entry("surv", "dangerous_swamp", 0, 1, 10, "", "Survival Level 1", "");
		campaign_entry("surv", "spider_lair", 0, 1, 10, "", "Survival Level 2", "");
		campaign_entry("surv", "ufo_invasion", 0, 1, 10, "", "Survival Level 3", "");
		campaign_entry("surv", "survive_pyramid", 0, 1, 10, "", "Survival Level 4", "");
		campaign_entry("surv", "dark_church", 0, 1, 10, "", "Survival Level 5", "");
		campaign_entry("surv", "survive_arena", 0, 1, 10, "", "Survival Level 6", "");
		campaign_entry("surv", "rex2dsurvdemo", 0, 1, 10, "", "Survival Level 8: 2d special", "");
		campaign_entry("surv", "surv_snowplace", 0, 1, 10, "", "Survival Level 8", "");
		campaign_entry("surv", "surv_canyon", 0, 1, 10, "", "Survival Level 9", "");
		campaign_entry("surv", "rextopviewsurvdemo", 0, 1, 10, "", "Survival Level 10: top-view special", "");
		campaign_entry("surv", "survive_desert", 0, 1, 10, "", "Survival Level 11", "");
		campaign_entry("surv", "area51", 0, 1, 10, "", "Survival Level 12: Secret base", "");
		campaign_entry("surv", "failed_experiment", 0, 1, 10, "", "Survival Level 13", "Final challenge");
	} else if (campaign_name == "spdemo") {
		campaign_entry("single", "rexsp01_city", 0, 1, 10, "", "Pre-Alpha GamePlay Demo", "");
	}
	return campaign_entries;
}

void() campaign_file_unload {
	float i;
	for(i = 0; i < CAMPAIGN_MAX_ENTRIES; ++i) {
		campaign_gametype[i] = NULL;
		campaign_mapname[i] = NULL;
		campaign_mutators[i] = NULL;
		campaign_shortdesc[i] = NULL;
		campaign_longdesc[i] = NULL;
	}
	campaign_entries = 0;
	campaign_title = NULL;
}

void(float n) campaign_setup_cvars_only {
	localcmd("set g_campaign 1\n");
	localcmd("set _campaign_name \""); localcmd(campaign_name); localcmd("\"\n");
	localcmd("set _campaign_index "); localcmd(ftos(n)); localcmd("\n");
	localcmd("set _gametype "); localcmd(campaign_gametype[n]); localcmd("\n");
	localcmd(strcat("maxplayers ", ftos(campaign_bots[n] + 1), "\nskill 4\n"));
}

void(float n) campaign_setup {
	localcmd("disconnect\n");
	campaign_setup_cvars_only(n);
	map_info_load_map(campaign_mapname[n]);
}
