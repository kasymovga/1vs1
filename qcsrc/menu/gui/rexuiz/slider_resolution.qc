void(entity me, float w, float h) gui_rexuiz_slider_resolution_add;
void(entity me) gui_rexuiz_slider_resolution_configure;
void(entity me) gui_rexuiz_slider_resolution_load;
void(entity me) gui_rexuiz_slider_resolution_save;

entity(void) gui_rexuiz_slider_resolution_spawn {
	entity me = gui_rexuiz_textslider_spawn();
	me.configureNexuizResolutionSlider = gui_rexuiz_slider_resolution_configure;
	me.addResolution = gui_rexuiz_slider_resolution_add;
	me.loadCvars = gui_rexuiz_slider_resolution_load;
	me.saveCvars = gui_rexuiz_slider_resolution_save;
	me.classname = "NexuizResolutionSlider";
	return me;
}

entity(void) gui_rexuiz_slider_resolution_make {
	entity me;
	me = gui_rexuiz_slider_resolution_spawn();
	me.configureNexuizResolutionSlider(me);
	return me;
}

void(entity me, float w, float h) gui_rexuiz_slider_resolution_add {
	me.addValue(me, str_zone_ifneeded(strcat(ftos(w), "x", ftos(h))), str_zone_ifneeded(strcat(ftos(w), " ", ftos(h))));
	// FIXME (in case you ever want to dynamically instantiate this): THIS IS NEVER FREED
}

void(entity me) gui_rexuiz_slider_resolution_configure {
	float i;
	vector r0, r, c;
	me.configureNexuizTextSlider(me, "vid_width");
	c = '0 0 0';
	r0 = '0 0 0';
	for (i = 0;; ++i) {
		r = getresolution(i);
		if (r_x == 0 && r_y == 0)
			break;

		if (r == r0)
			continue;

		r0 = r;
		if (r_x < 640 || r_y < 400)
			continue;

		c_x = 800;
		c_y = rint(c_x * r_y / r_x);
		if (c_y >= 600) {
			me.addResolution(me, r_x, r_y);
			continue;
		}
		c_y = 600;
		c_x = rint(c_y * r_x / r_y);
		me.addResolution(me, r_x, r_y);
	}
	me.configureNexuizTextSliderValues(me);
}

void(entity me) gui_rexuiz_slider_resolution_load {
	me.setValueFromIdentifier(me, strcat(cvar_string("vid_width"), " ", cvar_string("vid_height")));
}

void(entity me) gui_rexuiz_slider_resolution_save {
	if (me.value >= 0 || me.value < me.nValues) {
		tokenize_console(me.getIdentifier(me));
		cvar_set("vid_width", argv(0));
		cvar_set("vid_height", argv(1));
	}
}
