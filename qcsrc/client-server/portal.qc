float(entity forent, vector v0, vector dvx, vector dvy, vector dvz) portal_check_wire_frame_box {
	trace_line(v0, v0, TRUE, forent); if (trace_startsolid) return 0;
	float content = pointcontents(v0);
	if (content == CONTENT_WATER || content == CONTENT_LAVA || content == CONTENT_SLIME) return 0;
	content = pointcontents(v0 + dvx);
	if (content == CONTENT_WATER || content == CONTENT_LAVA || content == CONTENT_SLIME) return 0;
	content = pointcontents(v0 + dvy);
	if (content == CONTENT_WATER || content == CONTENT_LAVA || content == CONTENT_SLIME) return 0;
	content = pointcontents(v0 + dvy + dvx);
	if (content == CONTENT_WATER || content == CONTENT_LAVA || content == CONTENT_SLIME) return 0;
	trace_line(v0, v0 + dvx, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0, v0 + dvy, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0, v0 + dvz, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0 + dvx, v0 + dvx + dvy, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0 + dvx, v0 + dvx + dvz, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0 + dvy, v0 + dvy + dvx, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0 + dvy, v0 + dvy + dvz, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0 + dvz, v0 + dvz + dvx, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0 + dvz, v0 + dvz + dvy, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0 + dvx + dvy, v0 + dvx + dvy + dvz, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0 + dvx + dvz, v0 + dvx + dvy + dvz, TRUE, forent); if(trace_fraction < 1) return 0;
	trace_line(v0 + dvy + dvz, v0 + dvx + dvy + dvz, TRUE, forent); if(trace_fraction < 1) return 0;
	return 1;
}
