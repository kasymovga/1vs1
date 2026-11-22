entity spawnNexuizTextLabel() {
	entity me; me = gui_label_spawn();
	me.configureNexuizTextLabel = configureNexuizTextLabelNexuizTextLabel;
	me.draw = drawNexuizTextLabel;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.colorL = SKINCOLOR_TEXT;
	me.classname = "NexuizTextLabel";
	return me;
}
entity makeNexuizTextLabel(float theAlign, string theText);
entity makeNexuizTextLabel(float theAlign, string theText)
{
	entity me;
	me = spawnNexuizTextLabel();
	me.configureNexuizTextLabel(me, theAlign, theText);
	return me;
}
void configureNexuizTextLabelNexuizTextLabel(entity me, float theAlign, string theText)
{
	me.configureLabel(me, theText, me.fontSize, theAlign);
}
void drawNexuizTextLabel(entity me)
{
	drawLabel(me);
}
