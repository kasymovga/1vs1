#ifdef INTERFACE
CLASS(NexuizMutatorsDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizMutatorsDialog, toString, string(entity))
	METHOD(NexuizMutatorsDialog, fill, void(entity))
	METHOD(NexuizMutatorsDialog, showNotify, void(entity))
	METHOD(NexuizMutatorsDialog, close, void(entity))
	ATTRIB(NexuizMutatorsDialog, title, string, _("Mutators"))
	ATTRIB(NexuizMutatorsDialog, color, vector, SKINCOLOR_DIALOG_MUTATORS)
	ATTRIB(NexuizMutatorsDialog, intendedWidth, float, 0.4)
	ATTRIB(NexuizMutatorsDialog, rows, float, 10)
	ATTRIB(NexuizMutatorsDialog, columns, float, 4)
	ATTRIB(NexuizMutatorsDialog, refilterEntity, entity, NULL)
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
	if (profile_name == "cra") return "Camping Rifle Arena";
	if (profile_name == "explosive_minsta") return "Explosive Minsta+Hook";
	if (profile_name == "defragcpm") return "Defrag CPM";
	return "Unknown";
}

string(entity me) toStringNexuizMutatorsDialog {
	return profileDescriptionNexuizMutatorsDialog(cvar_string("g_profile"));
}

void fillNexuizMutatorsDialog(entity me) {
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeNexuizTextLabel(0, _("Gameplay mutators:")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "", profileDescriptionNexuizMutatorsDialog("")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "bestakimbo", profileDescriptionNexuizMutatorsDialog("bestakimbo")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "minsta", profileDescriptionNexuizMutatorsDialog("minsta")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "explosive_minsta", profileDescriptionNexuizMutatorsDialog("explosive_minsta")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "cra", profileDescriptionNexuizMutatorsDialog("cra")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "defragcpm", profileDescriptionNexuizMutatorsDialog("defragcpm")));

	me.gotoRC(me, me.rows - 1, 0);
	me.TD(me, 1, me.columns, e = makeNexuizButton(_("OK"), '0 0 0'));
		e.onClick = Dialog_Close;
		e.onClickEntity = me;

}

void(entity me) closeNexuizMutatorsDialog {
	if(me.refilterEntity)
		me.refilterEntity.refilter(me.refilterEntity);

	closeDialog(me);
}
#endif
