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

float(entity e, vector start, vector m1, vector m2, vector end, float movemode) trace_walk {
	vector org;
	vector move;
	vector dir;
	float dist;
	float totaldist;
	float stepdist;
	float yaw;
	float ignorehazards;
	float r = FALSE;
	move = end - start;
	move_z = 0;
	org = start;
	dist = totaldist = vlen(move);
	dir = normalize(move);
	stepdist = 32;
	ignorehazards = FALSE;
	// Analyze starting point
	trace_line(start, start, TRACE_MOVE_NORMAL, e);
	if (trace_dpstartcontents & (DPCONTENTS_SLIME | DPCONTENTS_LAVA))
		ignorehazards = TRUE;
	else {
		trace_line( start, start + '0 0 -65536', TRACE_MOVE_NORMAL, e);
		if (trace_dpstartcontents & (DPCONTENTS_SLIME | DPCONTENTS_LAVA)) {
			ignorehazards = TRUE;
		}
	}
	trace_box(start, m1, m2, start, TRACE_MOVE_NOMONSTERS, e);
	if (trace_startsolid) {
		goto finish;
		// Bad start
		//print("tracewalk: ", vtos(start), " is a bad start\n");
	}
	// Movement loop
	yaw = vectoyaw(move);
	move = end - org;
	for (;;) {
		if (math_boxes_overlap(end, end, org + m1 + '-1 -1 -1', org + m2 + '1 1 1')) {
			// Succeeded
			//print("tracewalk: ", vtos(start), " can reach ", vtos(end), "\n");
			r = TRUE;
			goto finish;
		}
		if (dist <= 0) {
			break;
		}
		if (stepdist > dist)
			stepdist = dist;

		dist = dist - stepdist;
		trace_line(org, org, TRACE_MOVE_NORMAL, e);
		if (!ignorehazards) {
			if (trace_dpstartcontents & (DPCONTENTS_SLIME | DPCONTENTS_LAVA)) {
				// hazards blocking path
				//print("tracewalk: ", vtos(start), " hits a hazard when trying to reach ", vtos(end), "\n");
				goto finish;
			}
		}
		if (trace_dpstartcontents & DPCONTENTS_LIQUIDSMASK) {
			move = normalize(end - org);
			trace_box(org, m1, m2, org + move * stepdist, movemode, e);
			if (trace_fraction < 1) {
				org = trace_endpos - normalize(org - trace_endpos) * stepdist;
				for (; org_z < end_z + self.maxs_z; org_z += stepdist) {
					if(pointcontents(org) == CONTENT_EMPTY)
						break;
				}
				if not(pointcontents(org + '0 0 1') == CONTENT_EMPTY) {
					goto finish;
				}
				continue;
			} else
				org = trace_endpos;
		} else {
			move = dir * stepdist + org;
			trace_box(org, m1, m2, move, movemode, e);
			// hit something
			if (trace_fraction < 1) {
				if (math_boxes_overlap(end, end, trace_endpos + m1 + '-1 -1 -1', trace_endpos + m2 + '1 1 1')) {
					r = TRUE;
					goto finish;
				}
				// check if we can walk over this obstacle
				trace_box(org + stepheightvec, m1, m2, move + stepheightvec, movemode, e);
				if (trace_fraction < 1 || trace_startsolid) {
					if (math_boxes_overlap(end, end, trace_endpos + m1 + '-1 -1 -1', trace_endpos + m2 + '1 1 1')) {
						r = TRUE;
						goto finish;
					}
					// check for doors
					trace_line( org, move, movemode, e);
					if ( trace_ent.classname == "door_rotating" || trace_ent.classname == "door") {
						vector nextmove;
						move = trace_endpos;
						while (trace_ent.classname == "door_rotating" || trace_ent.classname == "door") {
							nextmove = move + (dir * stepdist);
							trace_line( move, nextmove, movemode, e);
							move = nextmove;
						}
					} else {
						//print("tracewalk: ", vtos(start), " hit something when trying to reach ", vtos(end), "\n");
						//te_explosion(trace_endpos);
						//print(ftos(e.dphitcontentsmask), "\n");
						goto finish; // failed
					}
				} else
					move = trace_endpos;
			} else
				move = trace_endpos;

			// trace down from stepheight as far as possible and move there,
			// if this starts in solid we try again without the stepup, and
			// if that also fails we assume it is a wall
			// (this is the same logic as the Quake walkmove function used)
			trace_box(move, m1, m2, move + '0 0 -65536', movemode, e);
			if (trace_fraction > 0) {
				float f = trace_fraction;
				vector v = trace_endpos;
				vector move2 = move + dir * stepdist * 1.75; //check if we can step over
				trace_box(move, m1, m2, move2, movemode, e);
				if (trace_fraction == 1) {
					trace_box(move2, m1, m2, move2 + '0 0 -65536', movemode, e);
					if (trace_fraction >= f) //cannot step over, restore trace_endpos
						trace_endpos = v;
				} else //cannot step over, restore trace_endpos
					trace_endpos = v;
			}
			// moved successfully
			org = trace_endpos;
		}
	}
	//print("tracewalk: ", vtos(start), " did not arrive at ", vtos(end), " but at ", vtos(org), "\n");
	// moved but didn't arrive at the intended destination
:finish
	trace_endpos = org;
	return r;
}
