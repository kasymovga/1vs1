#ifdef INTERFACE
CLASS(NexuizMutatorsDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizMutatorsDialog, toString, string(entity))
	METHOD(NexuizMutatorsDialog, fill, void(entity))
	METHOD(NexuizMutatorsDialog, showNotify, void(entity))
	METHOD(NexuizMutatorsDialog, close, void(entity))
	ATTRIB(NexuizMutatorsDialog, title, string, "Mutators")
	ATTRIB(NexuizMutatorsDialog, color, vector, SKINCOLOR_DIALOG_MUTATORS)
	ATTRIB(NexuizMutatorsDialog, intendedWidth, float, 0.9)
	ATTRIB(NexuizMutatorsDialog, rows, float, 18)
	ATTRIB(NexuizMutatorsDialog, columns, float, 6)
	ATTRIB(NexuizMutatorsDialog, refilterEntity, entity, NULL)
ENDCLASS(NexuizMutatorsDialog)
#endif

#ifdef IMPLEMENTATION
void showNotifyNexuizMutatorsDialog(entity me)
{
	loadAllCvars(me);
}

string toStringNexuizMutatorsDialog(entity me)
{
	string s;
	s = "";
	if(cvar("g_minstagib"))
		s = strcat(s, ", MinstaGib");
	if(cvar("g_start_weapon_laser") == 0)
		s = strcat(s, ", No start weapons");
	if(cvar("sv_gravity") < 800)
		s = strcat(s, ", Low gravity");
	if(cvar("g_footsteps"))
		s = strcat(s, ", Steps");
	if(cvar("g_grappling_hook"))
		s = strcat(s, ", Hook");
	if(cvar("g_pinata"))
		s = strcat(s, ", Pinata");
	if(cvar("g_weapon_stay"))
		s = strcat(s, ", Weapons stay");
	if(cvar("g_jetpack"))
		s = strcat(s, ", Jet pack");
	if(s == "")
		return "None";
	else
		return substring(s, 2, strlen(s) - 2);
}

void fillNexuizMutatorsDialog(entity me)
{
	entity e, s;
	me.TR(me);
		me.TD(me, 1, 2, makeNexuizTextLabel(0, "Gameplay mutators:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_footsteps", "Footsteps"));
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeNexuizSlider(80, 400, 8, "sv_gravity");
			s.valueDigits = 0;
			s.valueDisplayMultiplier = 0.125; // show gravity in percent
		me.TD(me, 1, 2, e = makeNexuizSliderCheckBox(800, 1, s, "Low gravity"));
			e.savedValue = 200; // good on silvercity
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 1.8, s);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 2, makeNexuizTextLabel(0, "Weapon & item mutators:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_grappling_hook", "Grappling hook"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_jetpack", "Jet pack"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_pinata", "Pinata"));
		me.TR(me);
			me.TDempty(me, 0.4);
			me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_pinata_drop_all", "Drop all weapons"));
			setDependent(e, "g_pinata", 0, -1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_pickup_items", "Pickup items"));
		me.TR(me);
			me.TDempty(me, 0.4);
			me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_pickup_weapons", "Pickup weapons"));
			setDependent(e, "g_pickup_items", 0, -1);
			me.TR(me);
				me.TDempty(me, 0.6);
				me.TD(me, 1, 2, e = makeNexuizCheckBoxEx(2, 0, "g_weapon_stay", "Weapons stay"));
				setDependent(e, "g_pickup_items", 0, -1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_use_ammunition", "Use ammunition"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "g_minstagib", "MinstaGib"));

	me.gotoRC(me, 0, 2); me.setFirstColumn(me, me.currentColumn);
	me.TR(me);
		me.TD(me, 1, 4, makeNexuizTextLabel(0, "Start weapons:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Laser:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_laser"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Shotgun:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_shotgun"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Uzi:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_uzi"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Camping Rifle:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_campingrifle"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Mortar:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_grenadelauncher"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Crylink:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_crylink"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "HLAC:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_hlac"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Electro:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_electro"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Nex:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_nex"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Hagar:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_hagar"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Rocket Launcher:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_rocketlauncher"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "FireBall:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_fireball"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "HookGun:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_hook"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Porto:"));
		me.TD(me, 1, 1.2, s = makeNexuizTextSlider("g_start_weapon_porto"));
			s.addValue(s, "Default", "-1");
			s.addValue(s, "No", "0");
			s.addValue(s, "Yes", "1");
			s.configureNexuizTextSliderValues(s);

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
