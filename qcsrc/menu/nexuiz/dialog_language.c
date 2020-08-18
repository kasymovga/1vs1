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
void changeLanguage() {
	localcmd("menu_restart\ntogglemenu\n");
}

void fillNexuizLanguageDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2/3, e = makeNexuizRadioButton(1, "prvm_language", "", _("English")));
	me.TR(me);
		me.TD(me, 1, 2/3, e = makeNexuizRadioButton(1, "prvm_language", "ru", _("Русский")));
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("OK"), '0 0 0'));
			e.onClick = changeLanguage;
			e.onClickEntity = me;
}
#endif

