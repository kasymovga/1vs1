void(float i, string s) font_load_icon {
	localcmd("loadfontextrasymbol notify ", ftos(i), " ", s, "\n");
	localcmd("loadfontextrasymbol console ", ftos(i), " ", s, "\n");
}

void(void) font_load_icons {
	float i, n;
	if not(cvar_type("r_font_extra_symbols") & CVAR_TYPEFLAG_ENGINE) return;
	for (i = WEAPON_FIRST; i <= WEAPON_LAST; i++) {
		font_load_icon(i, weapon_info(i).icon);
	}
	if (dlc_ready("nadgets_v3")) {
		for (i = NADGET_START; i <= NADGET_END; i++) {
			n = i - NADGET_START + 32;
			font_load_icon(n, nadget_TypeToIcon(i, TRUE, FALSE));
		}
	}
	font_load_icon(FONT_ICON_LAVA, "textures/liquids/protolava.tga");
	font_load_icon(FONT_ICON_SLIME, "textures/liquids/slime1.tga");
	font_load_icon(FONT_ICON_FALL, "textures/evil3_floors/bdirt_blood.tga");
	font_load_icon(FONT_ICON_WATER, "textures/water/cheapwater-blue.tga");
	font_load_icon(FONT_ICON_VOID, "textures/evil8_fx/e8stars.tga");
	font_load_icon(FONT_ICON_KILL, "textures/trak4/exit.tga");
}
