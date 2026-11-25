void(entity me) gui_rexuiz_slider_decibels_load;
void(entity me) gui_rexuiz_slider_decibels_save;
string(entity me, float v) gui_rexuiz_slider_decibels_value_to_text;

entity(void) gui_rexuiz_slider_decibels_spawn {
	entity me = gui_rexuiz_slider_spawn();
	me.loadCvars = gui_rexuiz_slider_decibels_load;
	me.saveCvars = gui_rexuiz_slider_decibels_save;
	me.valueToText = gui_rexuiz_slider_decibels_value_to_text;
	me.classname = "NexuizDecibelsSlider";
	return me;
}

entity(float theValueMin, float theValueMax, float theValueStep, string theCvar) gui_rexuiz_slider_decibels_make {
	entity me;
	me = gui_rexuiz_slider_decibels_spawn();
	me.configureNexuizSlider(me, theValueMin, theValueMax, theValueStep, theCvar);
	return me;
}

void(entity me) gui_rexuiz_slider_decibels_load {
	float v;
	if not(me.cvarName)
		return;

	v = cvar(me.cvarName);
	if (v >= 0.98)
		me.value = 0;
	else if (v < 0.0005)
		me.value = -1000000;
	else
		me.value = 0.1 * floor(0.5 + 10.0 * vm_log(cvar(me.cvarName)) * 10 / 2.302585093);
}

void(entity me) gui_rexuiz_slider_decibels_save {
	if not(me.cvarName)
		return;

	if (me.value >= -0.1)
		cvar_set(me.cvarName, "1");

	if (me.value < -33)
		cvar_set(me.cvarName, "0");
	else
		cvar_set(me.cvarName, ftos(pow(2.7182818284, me.value / 10 * 2.302585093)));
}

string(entity me, float v) gui_rexuiz_slider_decibels_value_to_text {
	if (v < -33)
		return _("OFF");
	else if(v >= -0.1 && !me.valueMax)
		return _("MAX");

	return strcat(gui_slider_value_text(me, v), _(" dB"));
}
