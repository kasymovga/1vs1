#ifdef INTERFACE
CLASS(NexuizWeaponsDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizWeaponsDialog, toString, string(entity))
	METHOD(NexuizWeaponsDialog, fill, void(entity))
	METHOD(NexuizWeaponsDialog, showNotify, void(entity))
	ATTRIB(NexuizWeaponsDialog, title, string, _("Weapon settings"))
	ATTRIB(NexuizWeaponsDialog, color, vector, SKINCOLOR_DIALOG_WEAPONS)
	ATTRIB(NexuizWeaponsDialog, intendedWidth, float, 0.7)
	ATTRIB(NexuizWeaponsDialog, rows, float, 18)
	ATTRIB(NexuizWeaponsDialog, columns, float, 4)
	ATTRIB(NexuizWeaponsDialog, weaponsList, entity, NULL)
ENDCLASS(NexuizWeaponsDialog)
#endif

#ifdef IMPLEMENTATION
void(entity me) showNotifyNexuizWeaponsDialog {
	gui_load_all_cvars(me);
}

string(entity me) toStringNexuizWeaponsDialog {
	return me.weaponsList.toString(me.weaponsList);
}

void(entity me) fillNexuizWeaponsDialog {
	entity e;
	float h0, h;

	h = 8;
	
	me.TR(me);
		me.TD(me, 1, 2, makeNexuizTextLabel(0, _("Weapon priority list:")));
	me.TR(me);
		h0 = me.currentRow;
		me.TD(me, h, 1.25, e = me.weaponsList = makeNexuizWeaponsList());
	me.gotoRC(me, h0 + h / 2 - 1, 1.25);
		me.TD(me, 1, 0.5, e = makeNexuizButton(_("Up"), '0 0 0'));
			e.onClick = WeaponsList_MoveUp_Click;
			e.onClickEntity = me.weaponsList;
	me.gotoRC(me, h0 + h / 2, 1.25);
		me.TD(me, 1, 0.5, e = makeNexuizButton(_("Down"), '0 0 0'));
			e.onClick = WeaponsList_MoveDown_Click;
			e.onClickEntity = me.weaponsList;
	me.gotoRC(me, h0 + h, 0);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "cl_weaponpriority_useforcycling", _("Use priority list for weapon cycling")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "cl_autoswitch", _("Auto switch weapons on pickup")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "r_drawviewmodel", _("Draw 1st person weapon model")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, _("Weapon alpha:")));
			gui_set_dependent(e, "r_drawviewmodel", 1, 1);
			me.TD(me, 1, 2.5, e = makeNexuizSlider(0.05, 1, 0.05, "cl_gunalpha"));
				gui_set_dependent(e, "r_drawviewmodel", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, makeNexuizTextLabel(0, _("Align:")));
		me.TD(me, 1, 1.5, e = makeNexuizRadioButton(1, "cl_gunalign", "2", _("Left")));
		me.TD(me, 1, 1.5, e = makeNexuizRadioButton(1, "cl_gunalign", "1", _("Right")));
	me.TR(me);
		me.TDempty(me, 1);
		me.TD(me, 1, 1.5, e = makeNexuizRadioButton(1, "cl_gunalign", "4", _("Left or center")));
		me.TD(me, 1, 1.5, e = makeNexuizRadioButton(1, "cl_gunalign", "3", _("Right or center")));
	me.TR(me);
		me.TDempty(me, 1);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "cl_gunalign_force_center", _("Force center position")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeNexuizCheckBox(0, "cl_showweaponspawns", _("Weapon location hint")));
	me.gotoRC(me, 0, 2);
	me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2, makeNexuizTextLabel(0, _("Weapon models:")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Laser:")));
		me.TD(me, 1, 1, e = makeNexuizTextSlider("cl_lasermodel"));
			e.addValue(e, _("Default"), "0");
			e.addValue(e, _("Xon"), "1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Shotgun:")));
		me.TD(me, 1, 1, e = makeNexuizTextSlider("cl_sgmodel"));
			e.addValue(e, _("Default"), "0");
			e.addValue(e, _("Nex23"), "-1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Uzi:")));
		me.TD(me, 1, 1, e = makeNexuizTextSlider("cl_uzimodel"));
			e.addValue(e, _("Default"), "0");
			e.addValue(e, _("Nex23"), "-1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Nex/Minstanex:")));
		me.TD(me, 1, 1, e = makeNexuizTextSlider("cl_oldnexmodel"));
			e.addValue(e, _("Default"), "0");
			e.addValue(e, _("Classic"), "1");
			e.addValue(e, _("Xon"), "-1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Electro:")));
		me.TD(me, 1, 1, e = makeNexuizTextSlider("cl_electromodel"));
			e.addValue(e, _("Default"), "0");
			e.addValue(e, _("Nex23"), "-1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Rocket launcher:")));
		me.TD(me, 1, 1, e = makeNexuizTextSlider("cl_rlmodel"));
			e.addValue(e, _("Default"), "0");
			e.addValue(e, _("Nex23"), "-1");
			e.addValue(e, _("QuaRL"), "2");
			e.addValue(e, _("Xon"), "1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Grenade launcher:")));
		me.TD(me, 1, 1, e = makeNexuizTextSlider("cl_glmodel"));
			e.addValue(e, _("Default"), "0");
			e.addValue(e, _("Nex23"), "-1");
			e.addValue(e, _("Xon"), "1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Hagar:")));
		me.TD(me, 1, 1, e = makeNexuizTextSlider("cl_hagarmodel"));
			e.addValue(e, _("Default"), "0");
			e.addValue(e, _("Nex23"), "-1");
			e.addValue(e, _("Xon"), "1");
			e.configureNexuizTextSliderValues(e);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
