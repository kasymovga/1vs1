#ifdef INTERFACE
CLASS(NexuizColorpicker) EXTENDS(Image)
	METHOD(NexuizColorpicker, configureNexuizColorpicker, void(entity, entity))
	METHOD(NexuizColorpicker, mousePress, float(entity, vector))
	METHOD(NexuizColorpicker, mouseRelease, float(entity, vector))
	METHOD(NexuizColorpicker, mouseDrag, float(entity, vector))
	ATTRIB(NexuizColorpicker, controlledTextbox, entity, NULL)
	ATTRIB(NexuizColorpicker, image, string, SKINGFX_COLORPICKER)
	ATTRIB(NexuizColorpicker, imagemargin, vector, SKINMARGIN_COLORPICKER)
	ATTRIB(NexuizColorpicker, focusable, float, 1)
	METHOD(NexuizColorpicker, focusLeave, void(entity))
	METHOD(NexuizColorpicker, keyDown, float(entity, float, float, float))
	METHOD(NexuizColorpicker, draw, void(entity))
ENDCLASS(NexuizColorpicker)
entity makeNexuizColorpicker(entity theTextbox);
#endif

#ifdef IMPLEMENTATION

vector hue_mi_ma_to_rgb(float hue, float mi, float ma)
{
	vector rgb;

	hue -= 6 * floor(hue / 6);

	//else if(ma == rgb_x)
	//	hue = 60 * (rgb_y - rgb_z) / (ma - mi);
	if(hue <= 1)
	{
		rgb_x = ma;
		rgb_y = hue * (ma - mi) + mi;
		rgb_z = mi;
	}
	//else if(ma == rgb_y)
	//	hue = 60 * (rgb_z - rgb_x) / (ma - mi) + 120;
	else if(hue <= 2)
	{
		rgb_x = (2 - hue) * (ma - mi) + mi;
		rgb_y = ma;
		rgb_z = mi;
	}
	else if(hue <= 3)
	{
		rgb_x = mi;
		rgb_y = ma;
		rgb_z = (hue - 2) * (ma - mi) + mi;
	}
	//else // if(ma == rgb_z)
	//	hue = 60 * (rgb_x - rgb_y) / (ma - mi) + 240;
	else if(hue <= 4)
	{
		rgb_x = mi;
		rgb_y = (4 - hue) * (ma - mi) + mi;
		rgb_z = ma;
	}
	else if(hue <= 5)
	{
		rgb_x = (hue - 4) * (ma - mi) + mi;
		rgb_y = mi;
		rgb_z = ma;
	}
	//else if(ma == rgb_x)
	//	hue = 60 * (rgb_y - rgb_z) / (ma - mi);
	else // if(hue <= 6)
	{
		rgb_x = ma;
		rgb_y = mi;
		rgb_z = (6 - hue) * (ma - mi) + mi;
	}

	return rgb;
}


vector hsl_to_rgb(vector hsl)
{
	float mi, ma, maminusmi;

	if(hsl_z <= 0.5)
		maminusmi = hsl_y * 2 * hsl_z;
	else
		maminusmi = hsl_y * (2 - 2 * hsl_z);

	// hsl_z     = 0.5 * mi + 0.5 * ma
	// maminusmi =     - mi +       ma
	mi = hsl_z - 0.5 * maminusmi;
	ma = hsl_z + 0.5 * maminusmi;

	return hue_mi_ma_to_rgb(hsl_x, mi, ma);
}


string rgb_to_hexcolor(vector rgb)
{
	return
		strcat(
			"^x",
			DIGIT_DEC_TO_HEX(floor(rgb_x * 15 + 0.5)),
			DIGIT_DEC_TO_HEX(floor(rgb_y * 15 + 0.5)),
			DIGIT_DEC_TO_HEX(floor(rgb_z * 15 + 0.5))
		);
}

entity makeNexuizColorpicker(entity theTextbox)
{
	entity me;
	me = spawnNexuizColorpicker();
	me.configureNexuizColorpicker(me, theTextbox);
	return me;
}

void configureNexuizColorpickerNexuizColorpicker(entity me, entity theTextbox)
{
	me.controlledTextbox = theTextbox;
	me.configureImage(me, me.image);
}

float mousePressNexuizColorpicker(entity me, vector coords)
{
	me.mouseDrag(me, coords);
	return 1;
}

// must match hslimage.c
vector hslimage_color(vector v, vector margin)
{
    v_x = (v_x - margin_x) / (1 - 2 * margin_x);
    v_y = (v_y - margin_y) / (1 - 2 * margin_y);
    if(v_x < 0) v_x = 0;
    if(v_y < 0) v_y = 0;
    if(v_x > 1) v_x = 1;
    if(v_y > 1) v_y = 1;
    if(v_y > 0.875) // grey bar
        return hsl_to_rgb(eZ * v_x);
    else
        return hsl_to_rgb(v_x * 6 * eX + eY + v_y / 0.875 * eZ);
}

float mouseDragNexuizColorpicker(entity me, vector coords)
{
	float i;
	for(;;)
	{
		i = me.controlledTextbox.cursorPos;
		if(i >= 2)
		{
			if(substring(me.controlledTextbox.text, i-2, 1) == "^")
				if(strstrofs("0123456789", substring(me.controlledTextbox.text, i-1, 1), 0) >= 0)
				{
					me.controlledTextbox.keyDown(me.controlledTextbox, K_BACKSPACE, 8, 0);
					me.controlledTextbox.keyDown(me.controlledTextbox, K_BACKSPACE, 8, 0);
					continue;
				}
		}

		if(i >= 5)
		{
			if(substring(me.controlledTextbox.text, i-5, 2) == "^x")
				if(strstrofs("0123456789abcdefABCDEF", substring(me.controlledTextbox.text, i-3, 1), 0) >= 0)
					if(strstrofs("0123456789abcdefABCDEF", substring(me.controlledTextbox.text, i-2, 1), 0) >= 0)
						if(strstrofs("0123456789abcdefABCDEF", substring(me.controlledTextbox.text, i-1, 1), 0) >= 0)
						{
							me.controlledTextbox.keyDown(me.controlledTextbox, K_BACKSPACE, 8, 0);
							me.controlledTextbox.keyDown(me.controlledTextbox, K_BACKSPACE, 8, 0);
							me.controlledTextbox.keyDown(me.controlledTextbox, K_BACKSPACE, 8, 0);
							me.controlledTextbox.keyDown(me.controlledTextbox, K_BACKSPACE, 8, 0);
							me.controlledTextbox.keyDown(me.controlledTextbox, K_BACKSPACE, 8, 0);
							continue;
						}
		}
		break;
	}

	vector margin;
	margin = me.imagemargin;
	if(coords_x >= margin_x)
	if(coords_y >= margin_y)
	if(coords_x <= 1 - margin_x)
	if(coords_y <= 1 - margin_y)
		me.controlledTextbox.enterText(me.controlledTextbox, rgb_to_hexcolor(hslimage_color(coords, margin)));

	return 1;
}

float mouseReleaseNexuizColorpicker(entity me, vector coords)
{
	me.mouseDrag(me, coords);
	return 1;
}

void focusLeaveNexuizColorpicker(entity me)
{
	me.controlledTextbox.saveCvars(me.controlledTextbox);
}
float keyDownNexuizColorpicker(entity me, float key, float ascii, float shift)
{
	return me.controlledTextbox.keyDown(me.controlledTextbox, key, ascii, shift);
}
void drawNexuizColorpicker(entity me)
{
	drawImage(me);

	float B, C, aC;
	C = cvar("r_textcontrast");
	B = cvar("r_textbrightness");

	// for this to work, C/(1-B) must be in 0..1
	// B must be < 1
	// C must be < 1-B
	
	B = bound(0, B, 1);
	C = bound(0, C, 1-B);

	aC = 1 - C / (1 - B);
	gui_draw_picture(me.imgOrigin, strcat(me.src, "_m"), me.imgSize, '0 0 0', aC);
	gui_draw_picture(me.imgOrigin, strcat(me.src, "_m"), me.imgSize, me.color, B);
}
#endif
