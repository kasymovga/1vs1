float(string modelpath) player_model_path_check {
	if (modelpath != strtolower(modelpath))
		return FALSE;

	if (str_sub(modelpath, -4, 4) != ".zym")
	if (str_sub(modelpath, -4, 4) != ".dpm")
	if (str_sub(modelpath, -4, 4) != ".md3")
	if (str_sub(modelpath, -4, 4) != ".psk")
	if (str_sub(modelpath, -4, 4) != ".iqm")
		return FALSE;

	if (strstrofs(modelpath, " ", 0) >= 0)
		return FALSE;

	// forbid the LOD models
	if (str_sub(modelpath, -9, 5) == "_lod1")
		return FALSE;

	if (str_sub(modelpath, -9, 5) == "_lod2")
		return FALSE;

	// forbid the torso/head models
	if (str_sub(modelpath, -10, 6) == "_torso")
		return FALSE;

	if (str_sub(modelpath, -9, 5) == "_head")
		return FALSE;

	if (str_sub(modelpath, -15, 11) == "_decompiled")
		return FALSE;

	if (str_sub(modelpath, -13, 9) == "_compiled")
		return FALSE;

	if (strstrofs(modelpath, "/", 0) > 0 && str_sub(modelpath, 0, 14) != "models/player/")
		return FALSE;

	return TRUE;
}
