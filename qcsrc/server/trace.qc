void(entity ent, entity ignore, float toss_frametime, float toss_count) trace_toss {
	vector v0;
	float g0;
	v0 = ent.velocity;
	g0 = ent.gravity;
	ent.velocity = ent.velocity * toss_frametime * 20;
	ent.gravity *= (toss_frametime * toss_frametime * 400);
	builtin_tracetoss(ent, ignore);
	ent.velocity= v0;
	ent.gravity = g0;
	return;
}

float trace_hits_box_a0, trace_hits_box_a1;

float(float end, float thmi, float thma) trace_hits_box_1d {
    if (end == 0) {
        // just check if x is in range
        if (0 < thmi)
            return FALSE;

        if (0 > thma)
            return FALSE;
    } else {
        // do the trace with respect to x
        // 0 -> end has to stay in thmi -> thma
        trace_hits_box_a0 = max(trace_hits_box_a0, min(thmi / end, thma / end));
        trace_hits_box_a1 = min(trace_hits_box_a1, max(thmi / end, thma / end));
        if (trace_hits_box_a0 > trace_hits_box_a1)
            return FALSE;
    }
    return TRUE;
}

float(vector start, vector end, vector thmi, vector thma) trace_hits_box {
    end -= start;
    thmi -= start;
    thma -= start;
    // now it is a trace from 0 to end
    trace_hits_box_a0 = 0;
    trace_hits_box_a1 = 1;
    if (!trace_hits_box_1d(end_x, thmi_x, thma_x))
        return FALSE;

    if (!trace_hits_box_1d(end_y, thmi_y, thma_y))
        return FALSE;

    if (!trace_hits_box_1d(end_z, thmi_z, thma_z))
        return FALSE;

    return TRUE;
}

float(vector start, vector mi, vector ma, vector end, vector thmi, vector thma) trace_box_hits_box {
    return trace_hits_box(start, end, thmi - ma, thma - mi);
}
