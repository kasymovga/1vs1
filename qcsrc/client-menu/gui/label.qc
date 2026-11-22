entity(void) gui_label_spawn {
	entity me; me = gui_item_spawn();
	me.configureLabel = configureLabelLabel;
	me.draw = drawLabel;
	me.resizeNotify = resizeNotifyLabel;
	me.setText = setTextLabel;
	me.toString = toStringLabel;
	me.text = NULL;
	me.fontSize = 8;
	me.align = 0.5;
	me.allowCut = 0;
	me.allowColors = 0;
	me.keepspaceLeft = 0; // for use by subclasses (radiobuttons for example)
	me.keepspaceRight = 0;
	me.marginLeft = 0; // alternate way to specify keepspace* (in characters from the font)
	me.marginRight = 0;
	me.realFontSize = '0 0 0';
	me.realOrigin = '0 0 0';
	me.alpha = 0.7;
	me.colorL = '1 1 1';
	me.disabled = 0;
	me.disabledAlpha = 0.3;
	me.textEntity = NULL;
	me.allowWrap = 0;
	me.classname = "Label";
	return me;
}
string toStringLabel(entity me)
{
	return me.text;
}
void setTextLabel(entity me, string txt)
{
	me.text = txt;
	me.realOrigin_x = me.align * (1 - me.keepspaceLeft - me.keepspaceRight - min(me.realFontSize_x * gui_text_width(me.text, me.allowColors), (1 - me.keepspaceLeft - me.keepspaceRight))) + me.keepspaceLeft;
}
void resizeNotifyLabel(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	resizeNotifyItem(me, relOrigin, relSize, absOrigin, absSize);
	// absSize_y is height of label
	me.realFontSize_y = me.fontSize / absSize_y;
	me.realFontSize_x = me.fontSize / absSize_x;
	if (gui_draw_scale_x / gui_draw_scale_y < 1.5)
		me.realFontSize_x = 0.666 * me.realFontSize_x;
	if(me.marginLeft)
		me.keepspaceLeft = me.marginLeft * me.realFontSize_x;
	if(me.marginRight)
		me.keepspaceRight = me.marginRight * me.realFontSize_x;
	me.realOrigin_x = me.align * (1 - me.keepspaceLeft - me.keepspaceRight - min(me.realFontSize_x * gui_text_width(me.text, me.allowColors), (1 - me.keepspaceLeft - me.keepspaceRight))) + me.keepspaceLeft;
	me.realOrigin_y = 0.5 * (1 - me.realFontSize_y);
}
void configureLabelLabel(entity me, string txt, float sz, float algn)
{
	me.fontSize = sz;
	me.align = algn;
	me.setText(me, txt);
}
void drawLabel(entity me) {
	string t;
	vector o;
	if (me.disabled)
		gui_draw_alpha *= me.disabledAlpha;
	if (me.textEntity) {
		t = me.textEntity.toString(me.textEntity);
		me.realOrigin_x = me.align * (1 - me.keepspaceLeft - me.keepspaceRight - min(me.realFontSize_x * gui_text_width(t, 0), (1 - me.keepspaceLeft - me.keepspaceRight))) + me.keepspaceLeft;
	} else
		t = me.text;
	if (me.fontSize)
		if (t != "") {
			if (me.allowCut) // FIXME allowCut incompatible with align != 0
				gui_draw_text(me.realOrigin, gui_draw_text_shorten_to_width(t, (1 - me.keepspaceLeft - me.keepspaceRight) / me.realFontSize_x, me.allowColors), me.realFontSize, me.colorL, me.alpha, me.allowColors);
			else if (me.allowWrap) { // FIXME allowWrap incompatible with align != 0
				float nl = 0;
				string tl;
				o = me.realOrigin;
				while (t != "") {
					nl = strstrofs(t, "\n", 0);
					if (nl >= 0) {
						tl = str_sub(t, 0, nl);
						t = str_sub(t, nl + 1, -1);
					} else {
						tl = t;
						t = "";
					}
					if (tl == "") {
						o_y += me.realFontSize_y;
					} else {
						str_wrapped_line_remaining = tl;
						while (str_wrapped_line_remaining != "") {
						 if (me.allowColors)
						  tl = str_wrapped_line((1 - me.keepspaceLeft - me.keepspaceRight) / me.realFontSize_x, gui_text_width_with_colors);
						 else
						  tl = str_wrapped_line((1 - me.keepspaceLeft - me.keepspaceRight) / me.realFontSize_x, gui_text_width_without_colors);
						 gui_draw_text(o, tl, me.realFontSize, me.colorL, me.alpha, me.allowColors);
						 o_y += me.realFontSize_y;
						}
					}
				}
			} else
				gui_draw_text(me.realOrigin, t, me.realFontSize, me.colorL, me.alpha, me.allowColors);
		}
}
