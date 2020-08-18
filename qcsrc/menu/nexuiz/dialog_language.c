#ifdef INTERFACE
CLASS(NexuizLanguageDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizLanguageDialog, fill, void(entity))
	ATTRIB(NexuizLanguageDialog, title, string, _("Language"))
	ATTRIB(NexuizLanguageDialog, color, vector, SKINCOLOR_DIALOG_SETTINGS)
	ATTRIB(NexuizLanguageDialog, intendedWidth, float, 0.4)
	ATTRIB(NexuizLanguageDialog, rows, float, 4)
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
#if 0
	if (cvar_string("prvm_language") == "") {
		cvar_set("prvm_language", "en");
		cvar_set("_menu_show_language_dialog", "1");
	}
#endif
	cvar_set("_menu_current_language", cvar_string("prvm_language"));
	entity e;
	me.TR(me);
		me.TD(me, 1, 2/3, e = makeNexuizRadioButton(1, "prvm_language", "en", _("English")));
		e.onClick = changeLanguage;
	me.TR(me);
		me.TD(me, 1, 2/3, e = makeNexuizRadioButton(1, "prvm_language", "ru", _("Русский")));
		e.onClick = changeLanguage;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("Close"), '0 0 0'));
			e.onClick = DialogCloseButton_Click;
			e.onClickEntity = me;
}
#endif

