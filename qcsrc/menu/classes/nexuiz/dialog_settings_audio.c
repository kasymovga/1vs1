#ifdef INTERFACE
CLASS(NexuizAudioSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizAudioSettingsTab, fill, void(entity))
	ATTRIB(NexuizAudioSettingsTab, title, string, _("Audio"))
	ATTRIB(NexuizAudioSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizAudioSettingsTab, rows, float, 22)
	ATTRIB(NexuizAudioSettingsTab, columns, float, 6.5)
ENDCLASS(NexuizAudioSettingsTab)
entity makeNexuizAudioSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeNexuizAudioSettingsTab()
{
	entity me;
	me = spawnNexuizAudioSettingsTab();
	me.configureDialog(me);
	return me;
}

void fillNexuizAudioSettingsTab(entity me)
{
	entity e, s, sl;

	me.TR(me);
		s = makeNexuizDecibelsSlider(-20, 0, 0.5, "bgmvolume");
		me.TD(me, 1, 1, e = makeNexuizSliderCheckBox(-1000000, 1, s, _("Music:")));
		me.TD(me, 1, 2, s);
	me.TR(me);
	me.TR(me);
		s = makeNexuizDecibelsSlider(-20, 0, 0.5, "volume");
		me.TD(me, 1, 1, e = makeNexuizSliderCheckBox(-1000000, 1, s, _("Master:")));
		me.TD(me, 1, 2, s);
	me.TR(me);
		me.TDempty(me, 0.1);
		s = makeNexuizDecibelsSlider(-20, 0, 0.5, "snd_staticvolume");
		me.TD(me, 1, 0.9, e = makeNexuizSliderCheckBox(-1000000, 1, s, _("Ambient:")));
		gui_make_multi(s, "snd_entchannel2volume");
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "volume", "0");
		setDependentStringNotEqual(s, "volume", "0");
	me.TR(me);
		me.TDempty(me, 0.1);
		s = makeNexuizDecibelsSlider(-20, 0, 0.5, "snd_worldchannel0volume");
		me.TD(me, 1, 0.9, e = makeNexuizSliderCheckBox(-1000000, 1, s, _("Info:")));
		gui_make_multi(s, "snd_csqcchannel0volume");
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "volume", "0");
		setDependentStringNotEqual(s, "volume", "0");
	me.TR(me);
		me.TDempty(me, 0.1);
		s = makeNexuizDecibelsSlider(-20, 0, 0.5, "snd_entchannel3volume");
		gui_make_multi(s, "snd_playerchannel0volume snd_playerchannel3volume");
		me.TD(me, 1, 0.9, e = makeNexuizSliderCheckBox(-1000000, 1, s, _("Items:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "volume", "0");
		setDependentStringNotEqual(s, "volume", "0");
	me.TR(me);
		me.TDempty(me, 0.1);
		s = makeNexuizDecibelsSlider(-20, 0, 0.5, "snd_playerchannel6volume");
		gui_make_multi(s, "snd_csqcchannel6volume");
		me.TD(me, 1, 0.9, e = makeNexuizSliderCheckBox(-1000000, 1, s, _("Pain:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "volume", "0");
		setDependentStringNotEqual(s, "volume", "0");
	me.TR(me);
		me.TDempty(me, 0.1);
		s = makeNexuizDecibelsSlider(-20, 0, 0.5, "snd_playerchannel7volume");
		gui_make_multi(s, "snd_entchannel7volume");
		me.TD(me, 1, 0.9, e = makeNexuizSliderCheckBox(-1000000, 1, s, _("Player:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "volume", "0");
		setDependentStringNotEqual(s, "volume", "0");
	me.TR(me);
		me.TDempty(me, 0.1);
		s = makeNexuizDecibelsSlider(-20, 0, 0.5, "snd_entchannel4volume");
		gui_make_multi(s, "snd_playerchannel4volume snd_entchannel6volume snd_csqcchannel4volume");
		me.TD(me, 1, 0.9, e = makeNexuizSliderCheckBox(-1000000, 1, s, _("Shots:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "volume", "0");
		setDependentStringNotEqual(s, "volume", "0");
	me.TR(me);
		me.TDempty(me, 0.1);
		s = makeNexuizDecibelsSlider(-20, 0, 0.5, "snd_playerchannel2volume");
		me.TD(me, 1, 0.9, e = makeNexuizSliderCheckBox(-1000000, 1, s, _("Voice:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "volume", "0");
		setDependentStringNotEqual(s, "volume", "0");
	me.TR(me);
		me.TDempty(me, 0.1);
		s = makeNexuizDecibelsSlider(-20, 0, 0.5, "snd_playerchannel1volume");
		gui_make_multi(s, "snd_playerchannel5volume snd_entchannel1volume snd_entchannel5volume");
		me.TD(me, 1, 0.9, e = makeNexuizSliderCheckBox(-1000000, 1, s, _("Weapons:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "volume", "0");
		setDependentStringNotEqual(s, "volume", "0");

	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Frequency:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("snd_speed"));
			e.addValue(e, _("8 kHz"), "8000");
			e.addValue(e, _("11.025 kHz"), "11025");
			e.addValue(e, _("16 kHz"), "16000");
			e.addValue(e, _("22.05 kHz"), "22050");
			e.addValue(e, _("24 kHz"), "24000");
			e.addValue(e, _("32 kHz"), "32000");
			e.addValue(e, _("44.1 kHz"), "44100");
			e.addValue(e, _("48 kHz"), "48000");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Channels:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("snd_channels"));
			e.addValue(e, _("Mono"), "1");
			e.addValue(e, _("Stereo"), "2");
			e.addValue(e, "2.1", "3");
			e.addValue(e, "3.1", "4");
			e.addValue(e, "4.1", "5");
			e.addValue(e, "5.1", "6");
			e.addValue(e, "6.1", "7");
			e.addValue(e, "7.1", "8");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.8, e = makeNexuizCheckBox(0, "snd_swapstereo", _("Swap Stereo")));
		gui_set_dependent(e, "snd_channels", 1.5, 0.5);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.8, e = makeNexuizCheckBox(0, "snd_spatialization_control", _("Headphone friendly mode")));
		gui_set_dependent(e, "snd_channels", 1.5, 0.5);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Spatial voices:")));
		me.TD(me, 1, 2/3, e = makeNexuizRadioButton(1, "cl_voice_directional", "0", _("None")));
		me.TD(me, 1, 2/3, e = makeNexuizRadioButton(1, "cl_voice_directional", "2", _("Taunts")));
		me.TD(me, 1, 2/3, e = makeNexuizRadioButton(1, "cl_voice_directional", "1", _("All")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1.1, e = makeNexuizTextLabel(0, _("Taunt range:")));
		gui_set_dependent(e, "cl_voice_directional", 0.5, -0.5);
		me.TD(me, 1, 1.6, e = makeNexuizTextSlider("cl_voice_directional_taunt_attenuation"));
			e.addValue(e, _("Very short"), "3");
			e.addValue(e, _("Short"), "2");
			e.addValue(e, _("Normal"), "0.5");
			e.addValue(e, _("Long"), "0.25");
			e.addValue(e, _("Very long"), "0.015625");
			e.configureNexuizTextSliderValues(e);
		gui_set_dependent(e, "cl_voice_directional", 0.5, -0.5);
	me.TR(me);
		sl = makeNexuizSlider(0.15, 1, 0.05, "cl_autotaunt");
			sl.valueDisplayMultiplier = 100;
			sl.valueDigits = 0;
		me.TD(me, 1, 1, e = makeNexuizSliderCheckBox(0, 1, sl, _("Automatic taunts")));
		if(sl.value != e.savedValue)
			e.savedValue = 0.65; // default
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0.1, _("Frequency:")));
		me.TD(me, 1, 2, sl);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizTextLabel(0, _("Time warning:")));
		me.TD(me, 1, 1.5, e = makeNexuizTextSlider("cl_sound_maptime_warning"));
			e.addValue(e, _("None"), "0");
			e.addValue(e, _("1 minute"), "1");
			e.addValue(e, _("5 minutes"), "2");
			e.addValue(e, _("Both"), "3");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "cl_hitsound", _("Hit indicator")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "con_chatsound", _("Annoying chat beep sound")));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeNexuizCommandButton(_("Apply immediately"), '0 0 0', "snd_restart; sendcvar cl_hitsound; sendcvar cl_autotaunt; sendcvar cl_voice_directional; sendcvar cl_voice_directional_taunt_attenuation", COMMANDBUTTON_APPLY));
}
#endif
