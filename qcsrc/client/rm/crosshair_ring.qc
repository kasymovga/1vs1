float rm_crosshair_ring_fill;
#if 0
float rm_crosshair_ring_in_fill;
float rm_crosshair_ring_in_alpha;
float rm_crosshair_ring_in_expand;
#endif

void(vector wcross_origin, vector wcross_color, float wcross_alpha) rm_crosshair_ring_draw {
	float bullets, maxbullets;
	maxbullets = getstati(STAT_BULLETS_LOADED_MAX);
	string s;
	if (maxbullets > 0) {
		bullets = bound(0, getstati(STAT_BULLETS_LOADED), maxbullets);
	} else
		bullets = 0;

	#if 0
	if (bullets) {
		rm_crosshair_ring_in_expand = approach(rm_crosshair_ring_in_expand, 1, frametime * 2);
	} else {
		rm_crosshair_ring_in_expand = approach(rm_crosshair_ring_in_expand, 0, frametime * 4);
	}
	#endif
	if (maxbullets > 0) {
		rm_crosshair_ring_fill += (bullets / maxbullets - rm_crosshair_ring_fill) * frametime * 10;
		if (rm_crosshair_ring_fill > 1)
			rm_crosshair_ring_fill = 1;
	} else {
		rm_crosshair_ring_fill -= rm_crosshair_ring_fill * frametime * 10;
		if (rm_crosshair_ring_fill < 0)
			rm_crosshair_ring_fill = 0;
	}
	float ringsize = CVAR(rm_hud_crosshair_ring_size) * 24;
	float ringalpha = CVAR(rm_hud_crosshair_ring_alpha) * wcross_alpha;
	float ringexpand = 0.25; // TODO: cvar for this?
	if (ringsize > 0 && ringalpha > 0) {
		if (rm_crosshair_ring_fill) {
			if (maxbullets > 1 && maxbullets < 25)
				s = strcat("gfx/hud/ring", ftos(maxbullets), ".tga");
			else
				s = "gfx/hud/ring1.tga";

			draw_circle_clipped_pic(
					wcross_origin,
					ringsize,
					s,
					rm_crosshair_ring_fill,
					0.5 * wcross_color + '0.5 0.5 0.5',
					ringalpha,
					DRAWFLAG_ADDITIVE);
		}
		#if 0
		float in_cycle = getstatf(STAT_INNERRING_CYCLE);
		float in_fulltime = getstatf(STAT_INNERRING_FULLTIME);
		float in_invert = FALSE;
		if(in_cycle < 0) {
			in_cycle *= -1;
			in_invert = TRUE;
		}
		if (in_fulltime > 0) {
			rm_crosshair_ring_in_fill = 1 - bound(0, (in_fulltime - servertime) / in_cycle, 1);

			if(rm_crosshair_ring_in_fill && rm_crosshair_ring_in_fill < 1)
				rm_crosshair_ring_in_alpha = approach(rm_crosshair_ring_in_alpha, 1, frametime * 14);
			else
				rm_crosshair_ring_in_alpha = approach(rm_crosshair_ring_in_alpha, 0, frametime * 7);
		} else
			rm_crosshair_ring_in_alpha = approach(rm_crosshair_ring_in_alpha, 0, frametime * 7);

		if (rm_crosshair_ring_in_alpha) {
			draw_circle_clipped_pic(
				wcross_origin,
				ringsize * (1 + ringexpand * crosshair_inring_expand * rm_crosshair_ring_in_alpha),
				"gfx/hud/ring_inner.tga",
				if(in_invert) 1 - rm_crosshair_ring_in_fill else rm_crosshair_ring_in_fill,
				0.5 * wcross_color + '0.5 0.5 0.5',
				ringalpha * rm_crosshair_ring_in_alpha,
				DRAWFLAG_ADDITIVE
			);
		}
		#endif
	}
}
