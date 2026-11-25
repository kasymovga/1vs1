void(entity me) gui_rexuiz_textlabel_draw;
void(entity me, float theAlign, string theText) gui_rexuiz_textlabel_configure;

entity(void) gui_rexuiz_textlabel_spawn {
	entity me; me = gui_label_spawn();
	me.configureNexuizTextLabel = gui_rexuiz_textlabel_configure;
	me.draw = gui_rexuiz_textlabel_draw;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.colorL = SKINCOLOR_TEXT;
	me.classname = "NexuizTextLabel";
	return me;
}

entity(float theAlign, string theText) gui_rexuiz_textlabel_make {
	entity me = gui_rexuiz_textlabel_spawn();
	me.configureNexuizTextLabel(me, theAlign, theText);
	return me;
}

void(entity me, float theAlign, string theText) gui_rexuiz_textlabel_configure {
	me.configureLabel(me, theText, me.fontSize, theAlign);
}

void(entity me) gui_rexuiz_textlabel_draw {
	gui_label_draw(me);
}
