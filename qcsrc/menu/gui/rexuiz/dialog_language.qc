entity spawnNexuizLanguageDialog() {
	entity me; me = gui_rexuiz_dialog_spawn();
	me.fill = fillNexuizLanguageDialog;
	me.title = _("Language");
	me.color = SKINCOLOR_DIALOG_SETTINGS;
	me.intendedWidth = 0.4;
	me.rows = 6;
	me.columns = 2;
	me.classname = "NexuizLanguageDialog";
	return me;
}
void changeLanguage(entity me, entity e) {
	gui_radiobutton_click(me, e);
	if (cvar_string("_menu_current_language") != cvar_string("prvm_language")) {
		cvar_set("_menu_current_language", cvar_string("prvm_language"));
		cvar_set("_menu_show_language_dialog", "1");
		localcmd("menu_restart\ntogglemenu\n");
	}
}
void fillNexuizLanguageDialog(entity me) {
	registercvar("_menu_show_language_dialog", "0", 0);
	registercvar("_menu_current_language", "", 0);
	if (cvar_string("prvm_language") == "") {
		cvar_set("prvm_language", "en");
		cvar_set("_menu_show_language_dialog", "1");
	}
	cvar_set("_menu_current_language", cvar_string("prvm_language"));
	entity e;
	me.TR(me);
		me.TD(me, 1, 1/2, e = gui_rexuiz_radiobutton_make(1, "prvm_language", "en", "English"));
		e.onClick = changeLanguage;
		me.TD(me, 1, 1/2, e = gui_rexuiz_radiobutton_make(1, "prvm_language", "it", "Italiano"));
		e.onClick = changeLanguage;
		me.TD(me, 1, 1/2, e = gui_rexuiz_radiobutton_make(1, "prvm_language", "ru", "Русский"));
		e.onClick = changeLanguage;
		me.TD(me, 1, 1/2, e = gui_rexuiz_radiobutton_make(1, "prvm_language", "de", "Deutsch"));
		e.onClick = changeLanguage;
	me.TR(me);
		me.TD(me, 1, 1/2, e = gui_rexuiz_radiobutton_make(1, "prvm_language", "fr", "Français"));
		e.onClick = changeLanguage;
		me.TD(me, 1, 1/2, e = gui_rexuiz_radiobutton_make(1, "prvm_language", "pt", "Português"));
		e.onClick = changeLanguage;
		me.TD(me, 1, 1/2, e = gui_rexuiz_radiobutton_make(1, "prvm_language", "nl", "Nederlands"));
		e.onClick = changeLanguage;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 2, e = gui_rexuiz_checkbox_make(1, "utf8_oldfont_for_oldchars", _("Disable Nexuiz-compatible symbols")));
	me.TR(me);
		me.TDempty(me, 0.05);
		me.TD(me, 0.5, 1.9, e = gui_rexuiz_textlabel_make(0, _("* Needed for some european characters, player names might be displayed incorrectly")));
		e.allowWrap = 1;
		e.colorL = SKINCOLOR_TEXT_WARNING;
		e.fontSize = e.fontSize * 0.6;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Close"), '0 0 0'));
				e.onClick = DialogCloseButton_Click;
				e.onClickEntity = me;
}
