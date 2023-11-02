#ifdef INTERFACE
CLASS(NexuizMutatorsDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizMutatorsDialog, toString, string(entity))
	METHOD(NexuizMutatorsDialog, fill, void(entity))
	METHOD(NexuizMutatorsDialog, showNotify, void(entity))
	ATTRIB(NexuizMutatorsDialog, title, string, _("Mutators"))
	ATTRIB(NexuizMutatorsDialog, color, vector, SKINCOLOR_DIALOG_MUTATORS)
	ATTRIB(NexuizMutatorsDialog, intendedWidth, float, 0.5)
	ATTRIB(NexuizMutatorsDialog, rows, float, 10)
	ATTRIB(NexuizMutatorsDialog, columns, float, 4)
	ATTRIB(NexuizMutatorsDialog, currentProfile, entity, NULL)
	ATTRIB(NexuizMutatorsDialog, availableProfiles, entity, NULL)
ENDCLASS(NexuizMutatorsDialog)
#endif

#ifdef IMPLEMENTATION
void showNotifyNexuizMutatorsDialog(entity me) {
	gui_load_all_cvars(me);
}

string profileDescriptionNexuizMutatorsDialog(string profile_name) {
	if (profile_name == "") return "Default";
	if (profile_name == "bestakimbo") return "Best Akimbo";
	if (profile_name == "minsta") return "Minsta+Hook";
	if (profile_name == "minsta_duel") return "Minsta+Hook Duel";
	if (profile_name == "cra") return "Camping Rifle Arena";
	if (profile_name == "explosive_minsta") return "Explosive Minsta+Hook";
	if (profile_name == "defragcpm") return "Defrag CPM";
	if (profile_name == "overkill") return "OverKill";
	if (profile_name == "mixed_arts") return "Mixed Arts";
	if (profile_name == "nexuiz25") return "Nexuiz";
	if (profile_name == "physicscpma") return "RexuizProMod";
	if (profile_name == "quakiuz") return "Quakiuz";
	if (profile_name == "duel") return "Duel";
	return profile_name;
}

string(entity me) toStringNexuizMutatorsDialog {
	return profileDescriptionNexuizMutatorsDialog(cvar_string("g_profile"));
}

void(entity btn, entity me) addClickNexuizMutatorsDialog {
	if (me.currentProfile.nItems >= PROFILELIST_MAX) {
		print("Too much profiles\n");
		return;
	}
	string s = me.availableProfiles.toString(me.availableProfiles);
	if (s == "") {
		print("No profile selected\n");
		return;
	}
	string profile = cvar_string("g_profile");
	if (strstrofs(strcat(" ", profile, " "), strcat(" ", s, " "), 0) >= 0) {
		return;
	}
	profile = strcat(profile, " ", s);
	while (substring(profile, 0, 1) == " ")
		profile = substring(profile, 1, -1);

	while (substring(profile, -1, 1) == " ")
		profile = substring(profile, 0, strlen(profile) - 1);

	if (substring(profile, strlen(profile) - 1, 1) == " ") profile = substring(profile, 0, strlen(profile) - 1);
	if (substring(profile, 0, 1) == " ") profile = substring(profile, 1, -1);
	cvar_set("g_profile", profile);
	me.currentProfile.loadCvars(me.currentProfile);
	me.availableProfiles.loadCvars(me.availableProfiles);
}

void(entity btn, entity me) removeClickNexuizMutatorsDialog {
	if (me.currentProfile.nItems <= 0) return;
	string s = me.currentProfile.toString(me.currentProfile);
	string profile = cvar_string("g_profile");
	profile = strreplace("+", " ", profile);
	profile = strreplace(strcat(" ", s, " "), " ", strcat(" ", profile, " "));
	profile = strreplace("  ", " ", profile);
	if (substring(profile, strlen(profile) - 1, 1) == " ") profile = substring(profile, 0, strlen(profile) - 1);
	if (substring(profile, 0, 1) == " ") profile = substring(profile, 1, -1);
	cvar_set("g_profile", profile);
	me.currentProfile.loadCvars(me.currentProfile);
	me.availableProfiles.loadCvars(me.availableProfiles);
}

void fillNexuizMutatorsDialog(entity me) {
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeNexuizTextLabel(0, _("Gameplay mutators:")));
	me.TR(me);
		me.TD(me, 1, 1.75, makeNexuizTextLabel(0, _("Available:")));
		me.TDempty(me, 0.5);
		me.TD(me, 1, 1.75, makeNexuizTextLabel(0, _("Enabled:")));
	me.TR(me);
		me.TD(me, 7, 1.75, me.availableProfiles = e = makeNexuizAvailableProfilesList());
		me.TDempty(me, 0.5);
		me.TD(me, 7, 1.75, me.currentProfile = e = makeNexuizProfileList());
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 1.8);
		me.TD(me, 1, 0.4, e = makeNexuizButton(_(">>"), '0 0 0'));
		e.onClick = addClickNexuizMutatorsDialog;
		e.onClickEntity = me;
	me.TR(me);
		me.TDempty(me, 1.8);
		me.TD(me, 1, 0.4, e = makeNexuizButton(_("<<"), '0 0 0'));
		e.onClick = removeClickNexuizMutatorsDialog;
		e.onClickEntity = me;
	me.gotoRC(me, me.rows - 1, 0);
	me.TD(me, 1, me.columns, e = makeNexuizButton(_("OK"), '0 0 0'));
		e.onClick = Dialog_Close;
		e.onClickEntity = me;

}
#endif
