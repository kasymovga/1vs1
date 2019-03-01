.float muted; // to be used by prvm_edictset server playernumber muted 1
.float retard_last_say;

string(entity pl, string msg) chat_formatmessage {
    float p, p1, p2;
    float n;
    string escape;
    string replacement;
    p = 0;
    n = 7;
    while (1)
    {
        if (n < 1)
            break; // too many replacements
        n = n - 1;
        p1 = strstrofs(msg, "%", p); // NOTE: this destroys msg as it's a tempstring!
        p2 = strstrofs(msg, "\\", p); // NOTE: this destroys msg as it's a tempstring!

        if (p1 < 0)
            p1 = p2;
        if (p2 < 0)
            p2 = p1;
        p = min(p1, p2);

        if (p < 0)
            break;
        replacement = substring(msg, p, 2);
        escape = substring(msg, p + 1, 1);
        if (escape == "%")
            replacement = "%";
        else if (escape == "\\")
            replacement = "\\";
        else if (escape == "n")
            replacement = "\n";
        else if (escape == "a")
            replacement = ftos(floor(pl.armorvalue));
        else if (escape == "h")
            replacement = ftos(floor(pl.health));
        else if (escape == "l")
            replacement = NearestLocation(pl.origin);
        else if (escape == "y")
            replacement = NearestLocation(pl.cursor_trace_endpos);
        else if (escape == "d")
            replacement = NearestLocation(pl.death_origin);
        else if (escape == "s")
			replacement = ftos(floor(vlen(self.velocity)));
        else if (escape == "w")
        {
            float wep;
            wep = pl.weapon;
            if (!wep)
                wep = pl.switchweapon;
            if (!wep)
                wep = pl.cnt;
            replacement = W_Name(wep);
        }
        else if (escape == "W")
        {
            if (pl.items & IT_SHELLS) replacement = "shells";
            else if (pl.items & IT_NAILS) replacement = "bullets";
            else if (pl.items & IT_ROCKETS) replacement = "rockets";
            else if (pl.items & IT_CELLS) replacement = "cells";
            else replacement = "batteries"; // ;)
        }
        else if (escape == "x")
        {
            replacement = pl.cursor_trace_ent.netname;
            if (!replacement || !pl.cursor_trace_ent)
                replacement = "nothing";
        }
        else if (escape == "p")
        {
            if (pl.cursor_trace_ent && pl.cursor_trace_ent.classname == "player")
                replacement = pl.cursor_trace_ent.netname;
            else
                replacement = "(nobody)";
        }
        msg = strcat(substring(msg, 0, p), replacement, substring(msg, p+2, strlen(msg) - (p+2)));
        p = p + strlen(replacement);
    }
    return msg;
}
void(entity source, float teamsay, entity privatesay, string msgin, float floodcontrol) chat_say {
	string msgstr, colorstr, cmsgstr, namestr, fullmsgstr, sourcemsgstr, fullcmsgstr, sourcecmsgstr, privatemsgprefix;
	float flood, privatemsgprefixlen;
	entity head;
	if (g_chat_forbidden_words != "") {
		string s1, s2 = g_chat_forbidden_words;
		for (; s2 != ""; s2 = cdr(s2)) {
			s1 = car(s2);
			if (s1 == "") continue;
			if (strstrofs(strtolower(strdecolorize(msgin)), s1, 0) >= 0) {
				if (g_chat_forbidden_words_set_retard)
					source.retard = 1;
				else
					source.muted = 1;

				break;
			}
		}
	}

	if(source.retard > 0) {
		if (source.retard_last_say)
		if (time - source.retard_last_say < 60)
			return;

		source.retard_last_say = time;

		float n = tokenizebyseparator(cvar_string("sv_retard_say"), "|");
		if (n <= 0)
			return;

		n = floor(random(n));
		msgin = argv(n);
	}

	if(!teamsay && !privatesay)
		if(substring(msgin, 0, 1) == " ")
			msgin = substring(msgin, 1, strlen(msgin) - 1); // work around DP say bug (say_team does not have this!)

	msgin = chat_formatmessage(source, msgin);

	if(msgin == "")
		return;

	if(source.classname != "player" && source.team <= 0)
		colorstr = "^0"; // black for spectators
	else if(teamplay)
		colorstr = Team_ColorCode(source.team);
	else
		teamsay = FALSE;

	if(intermission_running)
		teamsay = FALSE;

	msgin = trigger_magicear_processmessage_forallears(source, teamsay, privatesay, msgin);
	if(msgin == "")
		return;

	if(g_chat_teamcolors)
		namestr = playername(source);
	else
		namestr = source.netname;

	namestr = strcat(namestr, "^0#", ftos(num_for_edict(source)));

	if(privatesay)
	{
		msgstr = strcat("\{1}\{13}* ^3", namestr, "^3 tells you: ^7");
		privatemsgprefixlen = strlen(msgstr);
		msgstr = strcat(msgstr, msgin);
		cmsgstr = strcat(colorstr, "^3", namestr, "^3 tells you:\n^7", msgin);
		if(g_chat_teamcolors)
			privatemsgprefix = strcat("\{1}\{13}* ^3You tell ", playername(privatesay), ": ^7");
		else
			privatemsgprefix = strcat("\{1}\{13}* ^3You tell ", privatesay.netname, ": ^7");
	}
	else if(teamsay)
	{
		msgstr = strcat("\{1}\{13}", colorstr, "(^3", namestr, colorstr, ") ^7", msgin);
		cmsgstr = strcat(colorstr, "(^3", namestr, colorstr, ")\n^7", msgin);
	}
	else
	{
		msgstr = strcat("\{1}", namestr, "^7: ", msgin);
		cmsgstr = "";
	}

	msgstr = strcat(strreplace("\n", " ", msgstr), "\n"); // newlines only are good for centerprint
	fullmsgstr = msgstr;
	fullcmsgstr = cmsgstr;

	// FLOOD CONTROL
	flood = 0;
	var .float flood_field;

	if(floodcontrol)
	{
		float flood_spl;
		float flood_burst;
		float flood_lmax;
		float lines;
		if(privatesay)
		{
			flood_spl = g_chat_flood_spl_tell;
			flood_burst = g_chat_flood_burst_tell;
			flood_lmax = g_chat_flood_lmax_tell;
			flood_field = floodcontrol_chattell;
		}
		else if(teamsay)
		{
			flood_spl = g_chat_flood_spl_team;
			flood_burst = g_chat_flood_burst_team;
			flood_lmax = g_chat_flood_lmax_team;
			flood_field = floodcontrol_chatteam;
		}
		else
		{
			flood_spl = g_chat_flood_spl;
			flood_burst = g_chat_flood_burst;
			flood_lmax = g_chat_flood_lmax;
			flood_field = floodcontrol_chat;
		}
		flood_burst = max(0, flood_burst - 1);
		// to match explanation in default.cfg, a value of 3 must allow three-line bursts and not four!

		// do flood control for the default line size
		getWrappedLine_remaining = msgstr;
		msgstr = "";
		lines = 0;
		while(getWrappedLine_remaining && (!flood_lmax || lines <= flood_lmax))
		{
			msgstr = strcat(msgstr, " ", getWrappedLine(82.4289758859709, strlennocol)); // perl averagewidth.pl < gfx/vera-sans.width
			++lines;
		}
		msgstr = substring(msgstr, 1, strlen(msgstr) - 1);

		if(getWrappedLine_remaining != "")
		{
			msgstr = strcat(msgstr, "\n");
			flood = 2;
		}

		if(time >= source.flood_field)
		{
			source.flood_field = max(time - flood_burst * flood_spl, source.flood_field) + lines * flood_spl;
		}
		else
		{
			flood = 1;
			msgstr = fullmsgstr;
		}

		if (timeoutStatus == 2) //when game is paused, no flood protection
			source.flood_field = flood = 0;
	}

	if(flood == 2)
	{
		if(g_chat_flood_notify_flooder)
		{
			sourcemsgstr = strcat(msgstr, "\n^3FLOOD CONTROL: ^7message too long, trimmed\n");
			sourcecmsgstr = "";
		}
		else
		{
			sourcemsgstr = fullmsgstr;
			sourcecmsgstr = fullcmsgstr;
		}
		cmsgstr = "";
	}
	else
	{
		sourcemsgstr = msgstr;
		sourcecmsgstr = cmsgstr;
	}

	if(!privatesay)
	if(source.classname != "player" && source.team <= 0)
	{
		if(teamsay || (g_chat_nospectators == 1) || (g_chat_nospectators == 2 && !inWarmupStage))
			teamsay = -1; // spectators
	}

	if(flood)
		print("NOTE: ", playername(source), "^7 is flooding.\n");
	else if (!teamsay && !privatesay && source.retard <= 0 && !source.muted)
		GameHookChain_PublicPlayerChat(source, msgin);

	// build sourcemsgstr by cutting off a prefix and replacing it by the other one
	if(privatesay)
		sourcemsgstr = strcat(privatemsgprefix, substring(sourcemsgstr, privatemsgprefixlen, -1));

	if(source.muted)
	{
		// always fake the message
		sprint(source, sourcemsgstr);
		if(cmsgstr != "" && !privatesay)
			centerprint(source, sourcecmsgstr);
	}
	else if(flood == 1)
	{
		if(g_chat_flood_notify_flooder)
			sprint(source, strcat("^3FLOOD CONTROL: ^7wait ^1", ftos(source.flood_field - time), "^3 seconds\n"));
		else
		{
			sprint(source, sourcemsgstr);
			if(cmsgstr != "" && !privatesay)
				centerprint(source, sourcecmsgstr);
		}
		if (g_chat_flood_damage_flooder)
		if not(source.deadflag)
			Damage(source, world, world, g_chat_flood_damage_flooder, DEATH_HURTTRIGGER, source.origin, '0 0 0');
	}
	else if(privatesay)
	{
		sprint(source, sourcemsgstr);
		sprint(privatesay, msgstr);
		if(cmsgstr != "")
			centerprint(privatesay, cmsgstr);
	}
	else if(teamsay > 0)
	{
		sprint(source, sourcemsgstr);
		if(sourcecmsgstr != "")
			centerprint(source, sourcecmsgstr);
		FOR_EACH_REALPLAYER(head) if(head.team == source.team)
			if(head != source)
			{
				sprint(head, msgstr);
				if(cmsgstr != "")
					centerprint(head, cmsgstr);
			}
	}
	else if(teamsay < 0)
	{
		sprint(source, sourcemsgstr);
		FOR_EACH_REALCLIENT(head) if(head.classname != "player" && head.team <= 0)
			if(head != source)
				sprint(head, msgstr);
	}
	else if(sourcemsgstr != msgstr)
	{
		sprint(source, sourcemsgstr);
		FOR_EACH_REALCLIENT(head)
			if(head != source)
				sprint(head, msgstr);
	}
	else
		bprint(msgstr);
}

.float BUTTON_CHAT;
#define chat_bubble_think ChatBubbleThink
void() chat_bubble_think {
	entity o = self.owner;
	if (o.playerid != self.playerid) {
		remove(self);
		return;
	}
	if (o.BUTTON_CHAT && o.modelindex && o.classname == "player") {
		if (self.effects & EF_NODRAW) {
			setattachment(self, o, "");
			setorigin(self, '0 0 15' + o.maxs_z * '0 0 1');
			self.effects &~= EF_NODRAW;
		}
	} else
		self.effects |= EF_NODRAW;

	self.nextthink = time;
}

void() chat_bubble_spawn {
	entity e = spawn();
	e.owner = self;
	e.exteriormodeltoclient = self;
	e.think = chat_bubble_think;
	e.nextthink = time;
	e.effects = EF_LOWPRECISION | EF_NODRAW;
	e.playerid = self.playerid;
	setmodel(e, "models/misc/chatbubble.spr");
}
