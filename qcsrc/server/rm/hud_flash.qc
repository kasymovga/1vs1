#define RM_HUD_FLASH_DEFAULT_TIME 1.5
#define RM_HUD_FLASH_DEFAULT_INT 0.5
#define RM_HUD_FLASH_DEFAULT_ALPHA 0.4

void(entity e, vector flashcolor, float staytime, float intensivity, float alph) rm_hud_flash {
	if (clienttype(e) != CLIENTTYPE_REAL)
		return;

	msg_entity = e;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_RM_HUDFLASH);
	net_write_coord(MSG_ONE, flashcolor_x);
	net_write_coord(MSG_ONE, flashcolor_y);
	net_write_coord(MSG_ONE, flashcolor_z);
	net_write_coord(MSG_ONE, staytime);
	net_write_coord(MSG_ONE, intensivity);
	net_write_coord(MSG_ONE, alph);
}

void(entity e, float staytime, float intensivity, float alph) rm_hud_flash_teamcolor {
	if (clienttype(e) != CLIENTTYPE_REAL)
		return;

	msg_entity = e;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_RM_HUDFLASH_TEAMCOLOR);
	net_write_coord(MSG_ONE, staytime);
	net_write_coord(MSG_ONE, intensivity);
	net_write_coord(MSG_ONE, alph);
}

void(entity pl, vector flashcolor, float staytime, float intensivity, float alph) rm_hud_flash_spec {
	entity e;
	FOR_EACH_REALCLIENT(e) if (e.classname == "spectator" && e.enemy == pl)
		rm_hud_flash(e, flashcolor, staytime, intensivity, alph);

	rm_hud_flash(pl, flashcolor, staytime, intensivity, alph);
}

void(entity pl, float staytime, float intensivity, float alph) rm_hud_flash_teamcolor_spec {
	entity e;
	FOR_EACH_REALCLIENT(e) if (e.classname == "spectator" && e.enemy == pl)
		rm_hud_flash_teamcolor(e, staytime, intensivity, alph);

	rm_hud_flash_teamcolor(pl, staytime, intensivity, alph);
}

void(entity e, vector flashcolor) rm_hud_flash_default {
	rm_hud_flash(e, flashcolor, RM_HUD_FLASH_DEFAULT_TIME, RM_HUD_FLASH_DEFAULT_INT, RM_HUD_FLASH_DEFAULT_ALPHA);
}

void(entity e, vector flashcolor) rm_hud_flash_default_spec {
	rm_hud_flash_spec(e, flashcolor, RM_HUD_FLASH_DEFAULT_TIME, RM_HUD_FLASH_DEFAULT_INT, RM_HUD_FLASH_DEFAULT_ALPHA);
}

void(entity e) rm_hud_flash_teamcolor_default {
	rm_hud_flash_teamcolor(e, RM_HUD_FLASH_DEFAULT_TIME, RM_HUD_FLASH_DEFAULT_INT, RM_HUD_FLASH_DEFAULT_ALPHA);
}

void(entity e) rm_hud_flash_teamcolor_default_spec {
	rm_hud_flash_teamcolor_spec(e, RM_HUD_FLASH_DEFAULT_TIME, RM_HUD_FLASH_DEFAULT_INT, RM_HUD_FLASH_DEFAULT_ALPHA);
}
