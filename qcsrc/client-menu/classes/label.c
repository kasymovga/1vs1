#ifdef INTERFACE
CLASS(Label) EXTENDS(Item)
	METHOD(Label, configureLabel, void(entity, string, float, float))
	METHOD(Label, draw, void(entity))
	METHOD(Label, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(Label, setText, void(entity, string))
	METHOD(Label, toString, string(entity))
	ATTRIB(Label, text, string, NULL)
	ATTRIB(Label, fontSize, float, 8)
	ATTRIB(Label, align, float, 0.5)
	ATTRIB(Label, allowCut, float, 0)
	ATTRIB(Label, allowColors, float, 0)
	ATTRIB(Label, keepspaceLeft, float, 0) // for use by subclasses (radiobuttons for example)
	ATTRIB(Label, keepspaceRight, float, 0)
	ATTRIB(Label, marginLeft, float, 0) // alternate way to specify keepspace* (in characters from the font)
	ATTRIB(Label, marginRight, float, 0)
	ATTRIB(Label, realFontSize, vector, '0 0 0')
	ATTRIB(Label, realOrigin, vector, '0 0 0')
	ATTRIB(Label, alpha, float, 0.7)
	ATTRIB(Label, colorL, vector, '1 1 1')
	ATTRIB(Label, disabled, float, 0)
	ATTRIB(Label, disabledAlpha, float, 0.3)
	ATTRIB(Label, textEntity, entity, NULL)
	ATTRIB(Label, allowWrap, float, 0)
ENDCLASS(Label)
#endif

#ifdef IMPLEMENTATION
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
void drawLabel(entity me)
{
	string t;
	vector o;
	if(me.disabled)
		gui_draw_alpha *= me.disabledAlpha;

	if(me.textEntity)
	{
		t = me.textEntity.toString(me.textEntity);
		me.realOrigin_x = me.align * (1 - me.keepspaceLeft - me.keepspaceRight - min(me.realFontSize_x * gui_text_width(t, 0), (1 - me.keepspaceLeft - me.keepspaceRight))) + me.keepspaceLeft;
	}
	else
		t = me.text;
	
	if(me.fontSize)
		if(t)
		{
			if(me.allowCut) // FIXME allowCut incompatible with align != 0
				gui_draw_text(me.realOrigin, gui_draw_text_shorten_to_width(t, (1 - me.keepspaceLeft - me.keepspaceRight) / me.realFontSize_x, me.allowColors), me.realFontSize, me.colorL, me.alpha, me.allowColors);
			else if(me.allowWrap) // FIXME allowWrap incompatible with align != 0
			{
				str_wrapped_line_remaining = t;
				o = me.realOrigin;
				while(str_wrapped_line_remaining)
				{
					if (me.allowColors)
						t = str_wrapped_line((1 - me.keepspaceLeft - me.keepspaceRight) / me.realFontSize_x, gui_text_width_WithColors);
					else
						t = str_wrapped_line((1 - me.keepspaceLeft - me.keepspaceRight) / me.realFontSize_x, gui_text_width_WithoutColors);
					gui_draw_text(o, t, me.realFontSize, me.colorL, me.alpha, me.allowColors);
					o_y += me.realFontSize_y;
				}
			}
			else
				gui_draw_text(me.realOrigin, t, me.realFontSize, me.colorL, me.alpha, me.allowColors);
		}
}
#endif
