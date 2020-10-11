#ifdef INTERFACE
CLASS(NexuizPlayerSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizPlayerSettingsTab, fill, void(entity))
	METHOD(NexuizPlayerSettingsTab, draw, void(entity))
	ATTRIB(NexuizPlayerSettingsTab, title, string, _("Player Setup"))
	ATTRIB(NexuizPlayerSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizPlayerSettingsTab, rows, float, 22)
	ATTRIB(NexuizPlayerSettingsTab, columns, float, 6.5)
	ATTRIB(NexuizPlayerSettingsTab, playerNameLabel, entity, NULL)
	ATTRIB(NexuizPlayerSettingsTab, playerNameLabelAlpha, float, 0)
ENDCLASS(NexuizPlayerSettingsTab)
entity makeNexuizPlayerSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeNexuizPlayerSettingsTab()
{
	entity me;
	me = spawnNexuizPlayerSettingsTab();
	me.configureDialog(me);
	return me;
}
void drawNexuizPlayerSettingsTab(entity me)
{
	if(cvar_string("_cl_name") == "Player")
		me.playerNameLabel.alpha = ((mod(time * 2, 2) < 1) ? 1 : 0);
	else
		me.playerNameLabel.alpha = me.playerNameLabelAlpha;
	drawContainer(me);
}
void fillNexuizPlayerSettingsTab(entity me)
{
	entity e, pms, sl, label, e0, box;
	float i, r, m, n;

	me.TR(me);
		me.TD(me, 1, 0.5, me.playerNameLabel = makeNexuizTextLabel(0, _("Name:")));
			me.playerNameLabelAlpha = me.playerNameLabel.alpha;
		me.TD(me, 1, 2.5, label = makeNexuizTextLabel(0, NULL));
			label.allowCut = 1;
			label.allowColors = 1;
			label.alpha = 1;
			label.nexuizFont = 1;
	me.TR(me);
		me.TD(me, 1, 3.0, box = makeNexuizInputBox(1, "_cl_name"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = 63;
			box.nexuizFont = 1;
			label.textEntity = box;
	me.TR(me);
		me.TD(me, 5, 1, e = makeNexuizColorpicker(box));
		me.TD(me, 5, 2, e = makeNexuizCharmap(box));
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.gotoRC(me, 8, 0.0);
		pms = makeNexuizPlayerModelSelector();
		me.TD(me, 1, 0.6, e = makeNexuizTextLabel(1, _("Model:")));
		me.TD(me, 1, 0.3, e = makeNexuizButton("<<", '0 0 0'));
			e.onClick = PlayerModelSelector_Prev_Click;
			e.onClickEntity = pms;
		me.TD(me, me.rows - me.currentRow - 1, 1.8, pms);
		me.TD(me, 1, 0.3, e = makeNexuizButton(">>", '0 0 0'));
			e.onClick = PlayerModelSelector_Next_Click;
			e.onClickEntity = pms;
	me.TR(me);
		r = me.currentRow;
		m = me.rows - r - 2;
		n = 16;
		m = m / (n - 1);
		for(i = 0; i < n; ++i)
		{
			me.gotoRC(me, r + i * m, 0.1);
			me.TDNoMargin(me, m, 0.2, e = makeNexuizColorButton(1, 0, i), '0 1 0');
		}
		for(i = 0; i < n; ++i)
		{
			me.gotoRC(me, r + i * m, 0.4);
			me.TDNoMargin(me, m, 0.2, e = makeNexuizColorButton(2, 1, i), '0 1 0');
		}

	me.gotoRC(me, 0, 3.25); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Field of View:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(60, 130, 1, "fov"));
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Damage kick:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 0.5, 0.05, "v_kicktime"));
	
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Zoom Factor:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(2, 16, 0.5, "cl_zoomfactor"));
	me.TR(me);
		sl = makeNexuizSlider(1, 8, 0.5, "cl_zoomspeed");
		me.TD(me, 1, 1.25, e = makeNexuizSliderCheckBox(-1, 1, sl, _("Zoom speed:")));
		me.TD(me, 1, 2, sl);
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizButton(_("Weapon settings..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.weaponsDialog;
		me.TD(me, 1, 2, e0 = makeNexuizTextLabel(0, NULL));
			e0.textEntity = main.weaponsDialog;
			e0.allowCut = 1;

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Show names:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("cl_shownames"));
			e.addValue(e, _("Never"), "0");
			e.addValue(e, _("Teammates"), "1");
			e.addValue(e, _("All players"), "2");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 2.25, e = makeNexuizCheckBox(0, "crosshair_per_weapon", _("Per weapon crosshairs")));
		me.TD(me, 1, 1.3, e = makeNexuizCheckBox(1, "crosshair_color_override", _("& crosshair colors")));
		setDependent(e, "crosshair_per_weapon", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Crosshair:")));
		for(i = 1; i <= 10; ++i) {
			me.TDNoMargin(me, 1, 2 / 10, e = makeNexuizCrosshairButton(3, i), '1 1 0');
			setDependent(e, "crosshair_per_weapon", 0, 0);
		}
	me.TR(me);
		me.TDempty(me, 1.25);
		for(i = 11; i <= 20; ++i) {
			me.TDNoMargin(me, 1, 2 / 10, e = makeNexuizCrosshairButton(3, i), '1 1 0');
			setDependent(e, "crosshair_per_weapon", 0, 0);
		}
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Crosshair Size:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0.40, 2, 0.05, "crosshair_size"));
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Crosshair Alpha:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 1, 0.01, "crosshair_color_alpha"));
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Crosshair Red:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 1, 0.01, "crosshair_color_red"));
		setDependentOR(e, "crosshair_per_weapon", 0, 0, "crosshair_color_override", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Crosshair Green:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 1, 0.01, "crosshair_color_green"));
		setDependentOR(e, "crosshair_per_weapon", 0, 0, "crosshair_color_override", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Crosshair Blue:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 1, 0.01, "crosshair_color_blue"));
		setDependentOR(e, "crosshair_per_weapon", 0, 0, "crosshair_color_override", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 2.2, e = makeNexuizButton(_("HUD & Waypoints..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.radarDialog;
		me.TDempty(me, 0.5);
	me.TR(me);
	#ifdef ALLOW_FORCEMODELS
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Force Models:")));
		me.TD(me, 1, 2/3, e = makeNexuizRadioButton(2, NULL, NULL, _("None")));
		me.TD(me, 1, 2/3, e = makeNexuizRadioButton(2, "cl_forceplayermodelsfromnexuiz", NULL, _("Custom")));
		me.TD(me, 1, 2/3, e = makeNexuizRadioButton(2, "cl_forceplayermodels", NULL, "All"));
	#endif
	me.TR(me);
		me.TD(me, 1, 3.25, e = makeNexuizCheckBox(0, "cl_gentle", _("Disable gore effects")));
	me.TR(me);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeNexuizCommandButton(_("Apply immediately"), '0 0 0', "color -1 -1;name \"$_cl_name\";sendcvar cl_weaponpriority;sendcvar cl_zoomfactor;sendcvar cl_zoomspeed;sendcvar cl_autoswitch;sendcvar cl_shownames;sendcvar cl_forceplayermodelsfromnexuiz;sendcvar cl_forceplayermodels;sendcvar cl_gunalpha", COMMANDBUTTON_APPLY));
}
#endif
