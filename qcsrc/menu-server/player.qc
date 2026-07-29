float(string modelpath) player_model_path_check {
	if (modelpath != strtolower(modelpath))
		return FALSE;

	if (substring(modelpath, -4, 4) != ".zym")
	if (substring(modelpath, -4, 4) != ".dpm")
	if (substring(modelpath, -4, 4) != ".md3")
	if (substring(modelpath, -4, 4) != ".psk")
	if (substring(modelpath, -4, 4) != ".iqm")
		return FALSE;

	if (strstrofs(modelpath, " ", 0) >= 0)
		return FALSE;

	// forbid the LOD models
	if (substring(modelpath, -9, 5) == "_lod1")
		return FALSE;

	if (substring(modelpath, -9, 5) == "_lod2")
		return FALSE;

	// forbid the torso/head models
	if (substring(modelpath, -10, 6) == "_torso")
		return FALSE;

	if (substring(modelpath, -9, 5) == "_head")
		return FALSE;

	if (substring(modelpath, -15, 11) == "_decompiled")
		return FALSE;

	if (substring(modelpath, -13, 9) == "_compiled")
		return FALSE;

	if (strstrofs(modelpath, "/", 0) > 0 && substring(modelpath, 0, 14) != "models/player/")
		return FALSE;

	return TRUE;
}
