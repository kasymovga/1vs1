#ifdef INTERFACE
CLASS(NexuizMutatorsDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizMutatorsDialog, toString, string(entity))
	METHOD(NexuizMutatorsDialog, fill, void(entity))
	METHOD(NexuizMutatorsDialog, showNotify, void(entity))
	METHOD(NexuizMutatorsDialog, close, void(entity))
	ATTRIB(NexuizMutatorsDialog, title, string, "Mutators")
	ATTRIB(NexuizMutatorsDialog, color, vector, SKINCOLOR_DIALOG_MUTATORS)
	ATTRIB(NexuizMutatorsDialog, intendedWidth, float, 0.4)
	ATTRIB(NexuizMutatorsDialog, rows, float, 10)
	ATTRIB(NexuizMutatorsDialog, columns, float, 4)
	ATTRIB(NexuizMutatorsDialog, refilterEntity, entity, NULL)
ENDCLASS(NexuizMutatorsDialog)
#endif

#ifdef IMPLEMENTATION
void showNotifyNexuizMutatorsDialog(entity me)
{
	loadAllCvars(me);
}

string profile_description(string profile_name) {
	if (profile_name == "") return "Default";
	if (profile_name == "akimbo") return "Akimbo";
	if (profile_name == "minsta") return "Minsta+Hook";
	if (profile_name == "cra") return "Camping Rifle Arena";
	if (profile_name == "explosive_minsta") return "Explosive Minsta+Hook";
	return "Unknown";
}

string toStringNexuizMutatorsDialog(entity me)
{
	return profile_description(cvar_string("g_profile"));
}

void fillNexuizMutatorsDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeNexuizTextLabel(0, "Gameplay mutators:"));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "", profile_description("")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "akimbo", profile_description("akimbo")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "minsta", profile_description("minsta")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "explosive_minsta", profile_description("explosive_minsta")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizRadioButton(1, "g_profile", "cra", profile_description("cra")));

	me.gotoRC(me, me.rows - 1, 0);
	me.TD(me, 1, me.columns, e = makeNexuizButton("OK", '0 0 0'));
		e.onClick = Dialog_Close;
		e.onClickEntity = me;

}

void closeNexuizMutatorsDialog(entity me)
{
	if(me.refilterEntity)
		me.refilterEntity.refilter(me.refilterEntity);
	closeDialog(me);
}
#endif
