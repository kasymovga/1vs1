#ifdef INTERFACE
CLASS(NexuizLanguageDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizLanguageDialog, fill, void(entity))
	ATTRIB(NexuizLanguageDialog, title, string, _("Language"))
	ATTRIB(NexuizLanguageDialog, color, vector, SKINCOLOR_DIALOG_SETTINGS)
	ATTRIB(NexuizLanguageDialog, intendedWidth, float, 0.4)
	ATTRIB(NexuizLanguageDialog, rows, float, 6)
	ATTRIB(NexuizLanguageDialog, columns, float, 2)
ENDCLASS(NexuizLanguageDialog)
#endif

#ifdef IMPLEMENTATION
void changeLanguage(entity me, entity e) {
	RadioButton_Click(me, e);
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
		me.TD(me, 1, 1/2, e = makeNexuizRadioButton(1, "prvm_language", "en", "English"));
		e.onClick = changeLanguage;
		me.TD(me, 1, 1/2, e = makeNexuizRadioButton(1, "prvm_language", "it", "Italiano"));
		e.onClick = changeLanguage;
		me.TD(me, 1, 1/2, e = makeNexuizRadioButton(1, "prvm_language", "ru", "Русский"));
		e.onClick = changeLanguage;
	me.TR(me);
		me.TD(me, 1, 1/2, e = makeNexuizRadioButton(1, "prvm_language", "de", "Deutsch"));
		e.onClick = changeLanguage;
		me.TD(me, 1, 1/2, e = makeNexuizRadioButton(1, "prvm_language", "fr", "Français"));
		e.onClick = changeLanguage;
		me.TD(me, 1, 1/2, e = makeNexuizRadioButton(1, "prvm_language", "pt", "Português"));
		e.onClick = changeLanguage;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(1, "utf8_oldfont_for_oldchars", _("Disable Nexuiz-compatible symbols")));
	me.TR(me);
		me.TDempty(me, 0.05);
		me.TD(me, 0.5, 1.9, e = makeNexuizTextLabel(0, _("* Needed for some european characters, player names might be displayed incorrectly")));
		e.allowWrap = 1;
		e.colorL = SKINCOLOR_TEXT_WARNING;
		e.fontSize = e.fontSize * 0.6;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("Close"), '0 0 0'));
			e.onClick = DialogCloseButton_Click;
			e.onClickEntity = me;
}
#endif

