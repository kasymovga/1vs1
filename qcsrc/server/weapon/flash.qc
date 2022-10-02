void weapon_flash_uzi_go() {
	if (self.frame > 10){
		stdproc_remove();
		return;
	}
	self.frame = self.frame + 2;
	self.alpha = self.alpha - 0.2;
	self.nextthink = time + 0.02;
}

entity(float t) weapon_flash_spawn {
	entity flash = spawn();
	switch (t) {
	case WEAPON_FLASH_UZI:
		setmodel(flash, "models/uziflash.md3"); // precision set below
		flash.think = weapon_flash_uzi_go;
		flash.nextthink = time + 0.02;
		flash.frame = 2;
		flash.alpha = 1;
		flash.effects = EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_LOWPRECISION;
		break;
	case WEAPON_FLASH_SHOTGUN:
		setmodel(flash, "models/uziflash.md3"); // precision set below
		flash.think = stdproc_remove;
		flash.nextthink = time + 0.06;
		flash.effects = EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_LOWPRECISION;
		break;
	case WEAPON_FLASH_ROCKET:
		setmodel(flash, "models/flash.md3"); // precision set below
		entity_fade_setup(flash, time, 0.1);
		break;
	default:
		backtrace(strcat("Unknown flash type: ", ftos(t), "\n"));
		remove(flash);
		return NULL;
	}
	flash.effects = EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_LOWPRECISION;
	return flash;
}

void(float t) weapon_flash {
	entity flash = weapon_flash_spawn(t);
	if (flash)
		weapon_attach_to_shotorg(flash, '5 0 0');
}

void(float t) weapon_flash_precache {
	switch (t) {
	case WEAPON_FLASH_UZI:
	case WEAPON_FLASH_SHOTGUN:
		precache_model("models/uziflash.md3");
		break;
	case WEAPON_FLASH_ROCKET:
		break;
	}
}
