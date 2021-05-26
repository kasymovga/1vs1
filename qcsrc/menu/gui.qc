void(entity root, void(entity, entity) funcPre, void(entity, entity) funcPost, entity pass) ui_for_all_descendant {
	gui_depth_first(root, parent, firstChild, nextSibling, funcPre, funcPost, pass);
}

.string cvarName;
void(entity e1, entity e2) gui_nothing_ee { }

void (entity ignore, entity e) gui_save_cvars_of {
	if(e.saveCvars)
		e.saveCvars(e);
}

void(entity ignore, entity e) gui_load_cvars_of {
	if(e.loadCvars)
		e.loadCvars(e);
}

void(entity root) gui_save_all_cvars {
	ui_for_all_descendant(root, gui_save_cvars_of, gui_nothing_ee, NULL);
}
void(entity root) gui_load_all_cvars {
	ui_for_all_descendant(root, gui_load_cvars_of, gui_nothing_ee, NULL);
}

.string cvarNames_Multi;
.void(entity me) saveCvars_Multi;
void(entity me) gui_save_cvars_multi {
	float n, i;
	string s;
	me.saveCvars_Multi(me);
	s = cvar_string(me.cvarName);
	n = tokenize_console(me.cvarNames_Multi);
	for (i = 0; i < n; ++i)
		cvar_set(argv(i), s);
}

void(entity e, string otherCvars) gui_make_multi {
	e.cvarNames_Multi = otherCvars;
	e.saveCvars_Multi = e.saveCvars;
	e.saveCvars = gui_save_cvars_multi;
}

.void(entity me) saveCvars_Callback;
.entity saveCvars_Callback_ent;
.void(entity me, entity cb) saveCvars_Callback_func;
void(entity me) gui_save_cvars_callback {
	me.saveCvars_Callback(me);
	me.saveCvars_Callback_func(me.saveCvars_Callback_ent, me);
}
void(entity e, entity cbent, void(entity, entity) cbfunc) gui_make_callback {
	e.saveCvars_Callback = e.saveCvars;
	e.saveCvars = gui_save_cvars_callback;
	e.saveCvars_Callback_ent = cbent;
	e.saveCvars_Callback_func = cbfunc;
}

.void(entity) draw_setDependent;
.string cvar_setDependent;
.float cvarMin_setDependent;
.float cvarMax_setDependent;
.string cvar2_setDependent;
.float cvar2Min_setDependent;
.float cvar2Max_setDependent;
.string cvar3_setDependent;
.float cvar3Min_setDependent;
.float cvar3Max_setDependent;
.float op_setDependent;
.string cvarString_setDependent;
.string cvarValue_setDependent;
void(entity e) gui_set_dependent_check {
	float f;
	string s;
	if (e.cvarString_setDependent) {
		s = cvar_string(e.cvarString_setDependent);
		e.disabled = (cvar_string(e.cvarString_setDependent) == e.cvarValue_setDependent);
	} else {
		if (e.cvar_setDependent) {
			f = cvar(e.cvar_setDependent);
			if(e.cvarMin_setDependent <= e.cvarMax_setDependent)
				e.disabled = ((f < e.cvarMin_setDependent) || (f > e.cvarMax_setDependent));
			else
				e.disabled = ((f >= e.cvarMax_setDependent) && (f <= e.cvarMin_setDependent));
		}
		if (e.cvar2_setDependent) {
			f = cvar(e.cvar2_setDependent);
			if(e.cvar2Min_setDependent <= e.cvar2Max_setDependent)
				e.disabled = (e.disabled + ((f < e.cvar2Min_setDependent) || (f > e.cvar2Max_setDependent)) > e.op_setDependent);
			else
				e.disabled = (e.disabled + ((f >= e.cvar2Max_setDependent) && (f <= e.cvar2Min_setDependent)) > e.op_setDependent);
		}
		if (e.cvar3_setDependent) {
			f = cvar(e.cvar3_setDependent);
			if (e.cvar3Min_setDependent <= e.cvar3Max_setDependent)
				e.disabled = (e.disabled + ((f < e.cvar3Min_setDependent) || (f > e.cvar3Max_setDependent)) > e.op_setDependent);
			else
				e.disabled = (e.disabled + ((f >= e.cvar3Max_setDependent) && (f <= e.cvar3Min_setDependent)) > e.op_setDependent);
		}
	}
}

void(entity e) gui_set_dependent_draw {
	gui_set_dependent_check(e);
	e.draw_setDependent(e);
}

void(entity e, string theCvarName, float theCvarMin, float theCvarMax) gui_set_dependent {
	e.draw_setDependent = e.draw;
	e.cvar_setDependent = theCvarName;
	e.cvarMin_setDependent = theCvarMin;
	e.cvarMax_setDependent = theCvarMax;
	e.cvar2_setDependent = NULL;
	e.cvar3_setDependent = NULL;
	e.draw = gui_set_dependent_draw;
	gui_set_dependent_check(e);
}

void setDependentStringNotEqual(entity e, string theCvarName, string theCvarValue) {
	e.draw_setDependent = e.draw;
	e.cvarString_setDependent = theCvarName;
	e.cvarValue_setDependent = theCvarValue;
	e.cvar_setDependent = NULL;
	e.cvar2_setDependent = NULL;
	e.cvar3_setDependent = NULL;
	e.draw = gui_set_dependent_draw;
	gui_set_dependent_check(e);
}

void setDependentAND(entity e, string theCvarName, float theCvarMin, float theCvarMax, string theCvar2Name, float theCvar2Min, float theCvar2Max) {
	e.draw_setDependent = e.draw;
	e.cvar_setDependent = theCvarName;
	e.cvarMin_setDependent = theCvarMin;
	e.cvarMax_setDependent = theCvarMax;
	e.cvar2_setDependent = theCvar2Name;
	e.cvar2Min_setDependent = theCvar2Min;
	e.cvar2Max_setDependent = theCvar2Max;
	e.cvar3_setDependent = NULL;
	e.op_setDependent = 0;
	e.draw = gui_set_dependent_draw;
	gui_set_dependent_check(e);
}

void setDependentOR(entity e, string theCvarName, float theCvarMin, float theCvarMax, string theCvar2Name, float theCvar2Min, float theCvar2Max) {
	e.draw_setDependent = e.draw;
	e.cvar_setDependent = theCvarName;
	e.cvarMin_setDependent = theCvarMin;
	e.cvarMax_setDependent = theCvarMax;
	e.cvar2_setDependent = theCvar2Name;
	e.cvar2Min_setDependent = theCvar2Min;
	e.cvar2Max_setDependent = theCvar2Max;
	e.cvar3_setDependent = NULL;
	e.op_setDependent = 1;
	e.draw = gui_set_dependent_draw;
	gui_set_dependent_check(e);
}

void(entity e, string theCvarName, float theCvarMin, float theCvarMax, string theCvar2Name, float theCvar2Min, float theCvar2Max, string theCvar3Name, float theCvar3Min, float theCvar3Max) gui_set_dependent_and3 {
	e.draw_setDependent = e.draw;
	e.cvar_setDependent = theCvarName;
	e.cvarMin_setDependent = theCvarMin;
	e.cvarMax_setDependent = theCvarMax;
	e.cvar2_setDependent = theCvar2Name;
	e.cvar2Min_setDependent = theCvar2Min;
	e.cvar2Max_setDependent = theCvar2Max;
	e.cvar3_setDependent = theCvar3Name;
	e.cvar3Min_setDependent = theCvar3Min;
	e.cvar3Max_setDependent = theCvar3Max;
	e.op_setDependent = 0;
	e.draw = gui_set_dependent_draw;
	gui_set_dependent_check(e);
}

void(entity start, .entity up, .entity downleft, .entity right, void(entity, entity) funcPre, void(entity, entity) funcPost, entity pass) gui_depth_first {
	entity e;
	e = start;
	funcPre(pass, e);
	while (e.downleft) {
		e = e.downleft;
		funcPre(pass, e);
	}
	funcPost(pass, e);
	while (e != start) {
		if (e.right) {
			e = e.right;
			funcPre(pass, e);
			while (e.downleft) {
				e = e.downleft;
				funcPre(pass, e);
			}
		} else
			e = e.up;

		funcPost(pass, e);
	}
}
