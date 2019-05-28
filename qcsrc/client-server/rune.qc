string rune_name(float r)
{
	if(r == RUNE_IGNITE)
		return "^1Ignite^7";
	if(r == RUNE_DEFENSE)
		return "^4Defense^7";
	if(r == RUNE_REGEN)
		return "^2Vitality^7";
	if(r == RUNE_SPEED)
		return "^3Speed^7";
	if(r == RUNE_VAMPIRE)
		return "^6Vampire^7";
	if(r == RUNE_HACKER)
		return "^5Hacker^7";
	if(r == RUNE_STUN)
		return "^x88fStun^7";

	return strcat("^8[unnamed", ftos(r), "]^7");
}
