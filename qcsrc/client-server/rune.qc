string(float r) rune_name {
	switch (r) {
	case RUNE_IGNITE:
		return "^1Ignite^7";
	case RUNE_DEFENSE:
		return "^4Defense^7";
	case RUNE_REGEN:
		return "^2Vitality^7";
	case RUNE_SPEED:
		return "^3Speed^7";
	case RUNE_VAMPIRE:
		return "^6Vampire^7";
	case RUNE_HACKER:
		return "^5Hacker^7";
	case RUNE_STUN:
		return "^x88fStun^7";
	}
	return strcat("^8[unnamed", ftos(r), "]^7");
}
