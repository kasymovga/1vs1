void(void) extension_init {
	extension_DP_CSQC_QUERYRENDERENTITY = checkextension("DP_CSQC_QUERYRENDERENTITY");
	extension_DP_RM_SETRENDERENTITY = checkextension("DP_RM_SETRENDERENTITY");
	extension_DP_RM_CVAR_ALTERTYPE = checkextension("DP_RM_CVAR_ALTERTYPE");
	extension_DP_RM_VOIP = checkextension("DP_RM_VOIP");
	extension_DP_RM_FILE = checkextension("DP_RM_FILE");
	//extension_DP_CSQC_ROTATEMOVES = checkextension("DP_CSQC_ROTATEMOVES");
	extension_ALL = (extension_DP_CSQC_QUERYRENDERENTITY && extension_DP_RM_SETRENDERENTITY && extension_DP_RM_CVAR_ALTERTYPE && extension_DP_RM_VOIP);
}
