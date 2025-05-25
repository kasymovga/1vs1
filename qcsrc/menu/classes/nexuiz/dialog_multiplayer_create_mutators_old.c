#ifdef INTERFACE
CLASS(NexuizOldMutatorsDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizOldMutatorsDialog, toString, string(entity))
	METHOD(NexuizOldMutatorsDialog, fill, void(entity))
//	METHOD(NexuizOldMutatorsDialog, showNotify, void(entity))
	METHOD(NexuizOldMutatorsDialog, close, void(entity))
	ATTRIB(NexuizOldMutatorsDialog, title, string, "Mutators")
	ATTRIB(NexuizOldMutatorsDialog, color, vector, SKINCOLOR_DIALOG_MUTATORS)
	ATTRIB(NexuizOldMutatorsDialog, intendedWidth, float, 0.9)
	ATTRIB(NexuizOldMutatorsDialog, rows, float, 20)
	ATTRIB(NexuizOldMutatorsDialog, columns, float, 6)
	ATTRIB(NexuizOldMutatorsDialog, refilterEntity, entity, NULL)
ENDCLASS(NexuizOldMutatorsDialog)
#endif

#ifdef IMPLEMENTATION
void showNotifyNexuizOldMutatorsDialog(entity me) {
	gui_load_all_cvars(me);
}

string toStringNexuizOldMutatorsDialog(entity me) {
	string s;
	s = "";
	if (cvar("g_minstagib")) s = strcat(s, ", MinstaGib");
	if (cvar("g_start_weapon_laser") == 0) s = strcat(s, ", No start weapons");
	if (cvar("g_gravity") < 800) s = strcat(s, ", Low gravity");
	if (cvar("g_footsteps")) s = strcat(s, ", Steps");
	if (cvar("g_grappling_hook")) s = strcat(s, ", Hook");
	if (cvar("g_pinata")) s = strcat(s, ", Pinata");
	if (cvar("g_weapon_stay")) s = strcat(s, ", Weapons stay");
	if (cvar("g_jetpack")) s = strcat(s, ", Jet pack");
	if (s == "") return "None";
	else return substring(s, 2, strlen(s) - 2);
}

void fillNexuizOldMutatorsDialog(entity me) {
	entity e, s;
	me.TR(me);
		me.TD(me, 1, 2, makeNexuizTextLabel(0, _("Gameplay mutators:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_footsteps", _("Footsteps")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.4, e = makeNexuizTextLabel(0, _("Gravity:")));
		me.TD(me, 1, 0.4, s = makeNexuizSlider(80, 1600, 8, "g_gravity"));
			s.valueDigits = 0;
			s.valueDisplayMultiplier = 0.125; // show gravity in percent
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_runes", _("Runes")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_grappling_hook", _("Grappling hook")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_jetpack", _("Jet pack")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_pinata", _("Pinata")));
		me.TR(me);
			me.TDempty(me, 0.4);
			me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_pinata_drop_all", _("Drop all weapons")));
			gui_set_dependent(e, "g_pinata", 0, -1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_pickup_items", _("Pickup items")));
		me.TR(me);
			me.TDempty(me, 0.4);
			me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_pickup_weapons", _("Pickup weapons")));
			gui_set_dependent(e, "g_pickup_items", 0, -1);
			me.TR(me);
				me.TDempty(me, 0.6);
				me.TD(me, 1, 2, e = makeNexuizCheckBoxEx(2, 0, "g_weapon_stay", _("Weapons stay")));
				gui_set_dependent(e, "g_pickup_items", 0, -1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_use_ammunition", _("Use ammunition")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_minstagib", _("MinstaGib")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.6, e = makeNexuizTextLabel(0, _("Akimbo:")));
		me.TD(me, 1, 0.6, s = makeNexuizTextSlider("g_akimbo_weapons"));
			s.addValue(s, _("None"), "none");
			s.addValue(s, _("Laser"), "laser");
			s.addValue(s, _("All"), "all");
			s.configureNexuizTextSliderValues(s);
	me.gotoRC(me, 0, 2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 4, makeNexuizTextLabel(0, _("Start weapons:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_chainsaw", "Chainsaw:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_laser", "Laser:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_shotgun", "Shotgun:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_uzi", "Uzi:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_campingrifle", "Camping Rifle:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_grenadelauncher", "Mortar:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_crylink", "Crylink:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_hlac", "HLAC:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_electro", "Electro:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_nex", "Nex:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_hagar", "Hagar:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_rocketlauncher", "Rocket Launcher:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_fireball", "FireBall:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_hook", "HookGun:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_porto", "Porto:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_supershotgun", "Supershotgun:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "g_start_weapon_zapper", "Zapper:"));
	me.gotoRC(me, 0, 4.4); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1.2, makeNexuizTextLabel(0, _("Start ammo:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.4, e = makeNexuizTextLabel(0, "Shells:"));
		me.TD(me, 1, 0.6, s = makeNexuizSlider(0, 100, 5, "g_start_ammo_shells"));
		gui_set_dependent(s, "g_use_ammunition", 0, -1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.4, e = makeNexuizTextLabel(0, "Rockets:"));
		me.TD(me, 1, 0.6, s = makeNexuizSlider(0, 100, 5, "g_start_ammo_rockets"));
		gui_set_dependent(s, "g_use_ammunition", 0, -1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.4, e = makeNexuizTextLabel(0, "Bullets:"));
		me.TD(me, 1, 0.6, s = makeNexuizSlider(0, 100, 5, "g_start_ammo_nails"));
		gui_set_dependent(s, "g_use_ammunition", 0, -1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.4, e = makeNexuizTextLabel(0, "Cells:"));
		me.TD(me, 1, 0.6, s = makeNexuizSlider(0, 100, 5, "g_start_ammo_cells"));
		gui_set_dependent(s, "g_use_ammunition", 0, -1);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton("OK", '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

void closeNexuizOldMutatorsDialog(entity me) {
	if (me.refilterEntity)
		me.refilterEntity.refilter(me.refilterEntity);

	closeDialog(me);
}
#endif
