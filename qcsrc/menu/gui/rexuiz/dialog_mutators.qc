void(entity me) gui_rexuiz_dialog_mutators_show;
string(entity me) gui_rexuiz_dialog_mutators_to_string;
void(entity me) gui_rexuiz_dialog_mutators_fill;

entity(void) gui_rexuiz_dialog_mutators_spawn {
	entity me = gui_rexuiz_dialog_spawn();
	me.toString = gui_rexuiz_dialog_mutators_to_string;
	me.fill = gui_rexuiz_dialog_mutators_fill;
	me.showNotify = gui_rexuiz_dialog_mutators_show;
	me.title = _("Mutators");
	me.color = SKINCOLOR_DIALOG_MUTATORS;
	me.intendedWidth = 0.5;
	me.rows = 10;
	me.columns = 4;
	me.currentProfile = NULL;
	me.availableProfiles = NULL;
	me.classname = "NexuizMutatorsDialog";
	return me;
}

void(entity me) gui_rexuiz_dialog_mutators_show {
	gui_load_all_cvars(me);
}

string(string profile_name) gui_rexuiz_dialog_mutators_profile_description {
	if (profile_name == "") return "Default";
	if (strstrofs(profile_name, " ", 0) >= 0)
		return profile_name;
	else {
		string s = cvar_string(strcat(profile_name, "_profile"));
		if (s != "") return s;
	}
	return profile_name;
}

string(entity me) gui_rexuiz_dialog_mutators_to_string {
	return gui_rexuiz_dialog_mutators_profile_description(cvar_string("g_profile"));
}

void(entity btn, entity me) gui_rexuiz_dialog_mutators_add_click {
	if (me.currentProfile.nItems >= GUI_REXUIZ_PROFILELIST_MAX) {
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
	while (str_sub(profile, 0, 1) == " ")
		profile = str_sub(profile, 1, -1);
	while (str_sub(profile, -1, 1) == " ")
		profile = str_sub(profile, 0, strlen(profile) - 1);
	if (str_sub(profile, strlen(profile) - 1, 1) == " ") profile = str_sub(profile, 0, strlen(profile) - 1);
	if (str_sub(profile, 0, 1) == " ") profile = str_sub(profile, 1, -1);
	cvar_set("g_profile", profile);
	me.currentProfile.loadCvars(me.currentProfile);
	me.availableProfiles.loadCvars(me.availableProfiles);
}

void(entity btn, entity me) gui_rexuiz_dialog_mutators_remove_click {
	if (me.currentProfile.nItems <= 0) return;
	string s = me.currentProfile.toString(me.currentProfile);
	string profile = cvar_string("g_profile");
	profile = strreplace("+", " ", profile);
	profile = strreplace(strcat(" ", s, " "), " ", strcat(" ", profile, " "));
	profile = strreplace("  ", " ", profile);
	if (str_sub(profile, strlen(profile) - 1, 1) == " ") profile = str_sub(profile, 0, strlen(profile) - 1);
	if (str_sub(profile, 0, 1) == " ") profile = str_sub(profile, 1, -1);
	cvar_set("g_profile", profile);
	me.currentProfile.loadCvars(me.currentProfile);
	me.availableProfiles.loadCvars(me.availableProfiles);
}

void(entity me) gui_rexuiz_dialog_mutators_fill {
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, gui_rexuiz_textlabel_make(0, _("Gameplay mutators:")));
	me.TR(me);
		me.TD(me, 1, 1.75, gui_rexuiz_textlabel_make(0, _("Available:")));
		me.TDempty(me, 0.5);
		me.TD(me, 1, 1.75, gui_rexuiz_textlabel_make(0, _("Enabled:")));
	me.TR(me);
		me.TD(me, 7, 1.75, me.availableProfiles = e = gui_rexuiz_availableprofiles_make());
		me.TDempty(me, 0.5);
		me.TD(me, 7, 1.75, me.currentProfile = e = gui_rexuiz_profilelist_make());
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 1.8);
		me.TD(me, 1, 0.4, e = gui_rexuiz_button_make(_(">>"), '0 0 0'));
		e.onClick = gui_rexuiz_dialog_mutators_add_click;
		e.onClickEntity = me;
	me.TR(me);
		me.TDempty(me, 1.8);
		me.TD(me, 1, 0.4, e = gui_rexuiz_button_make(_("<<"), '0 0 0'));
		e.onClick = gui_rexuiz_dialog_mutators_remove_click;
		e.onClickEntity = me;
	me.gotoRC(me, me.rows - 1, 0);
	me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("OK"), '0 0 0'));
		e.onClick = gui_dialog_button_close;
		e.onClickEntity = me;
}
