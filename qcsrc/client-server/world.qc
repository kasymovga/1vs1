void(float mode) world_get_min_max {
	vector mi, ma;
#ifdef CSQC
	mi = world.mins;
	ma = world.maxs;
#else
	mi = world.absmin;
	ma = world.absmax;
#endif
	world_min = mi;
	world_max = ma;
	// not specified
	if(mode) {
		// be clever
		trace_box('1 0 0' * mi_x,
				 '0 1 0' * mi_y + '0 0 1' * mi_z,
				 '0 1 0' * ma_y + '0 0 1' * ma_z,
				 '1 0 0' * ma_x,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_min_x = trace_endpos_x;

		trace_box('0 1 0' * mi_y,
				 '1 0 0' * mi_x + '0 0 1' * mi_z,
				 '1 0 0' * ma_x + '0 0 1' * ma_z,
				 '0 1 0' * ma_y,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_min_y = trace_endpos_y;

		trace_box('0 0 1' * mi_z,
				 '1 0 0' * mi_x + '0 1 0' * mi_y,
				 '1 0 0' * ma_x + '0 1 0' * ma_y,
				 '0 0 1' * ma_z,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_min_z = trace_endpos_z;

		trace_box('1 0 0' * ma_x,
				 '0 1 0' * mi_y + '0 0 1' * mi_z,
				 '0 1 0' * ma_y + '0 0 1' * ma_z,
				 '1 0 0' * mi_x,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_max_x = trace_endpos_x;

		trace_box('0 1 0' * ma_y,
				 '1 0 0' * mi_x + '0 0 1' * mi_z,
				 '1 0 0' * ma_x + '0 0 1' * ma_z,
				 '0 1 0' * mi_y,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_max_y = trace_endpos_y;

		trace_box('0 0 1' * ma_z,
				 '1 0 0' * mi_x + '0 1 0' * mi_y,
				 '1 0 0' * ma_x + '0 1 0' * ma_y,
				 '0 0 1' * mi_z,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_max_z = trace_endpos_z;
	}
}
