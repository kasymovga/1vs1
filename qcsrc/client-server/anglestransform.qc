// angles transforms
vector(vector transform, vector v) anglestransform_apply {
	makevectors(transform);
	return v_forward * v_x
		+ v_right   * (-v_y)
		+ v_up      * v_z;
}

vector(vector t1, vector t2) anglestransform_multiply {
	vector m_forward, m_up;
	makevectors(t2); m_forward = v_forward; m_up = v_up;
	m_forward = anglestransform_apply(t1, m_forward); m_up = anglestransform_apply(t1, m_up);
	vector a = vectoangles2(m_forward, m_up);
	a_x = -a_x;
	return a;
}

vector(vector transform) anglestransform_invert {
	vector i_forward, i_up;
	makevectors(transform);
	// we want angles that turn v_forward into '1 0 0', v_right into '0 1 0' and v_up into '0 0 1'
	// but these are orthogonal unit vectors!
	// so to invert, we can simply fixedvectoangles the TRANSPOSED matrix
	// TODO is this always -transform?
	i_forward_x = v_forward_x;
	i_forward_y = -v_right_x;
	i_forward_z = v_up_x;
	i_up_x = v_forward_z;
	i_up_y = -v_right_z;
	i_up_z = v_up_z;
	vector a = vectoangles2(i_forward, i_up);
	a_x = -a_x;
	return a;
}

vector(vector transform) anglestransform_turn_direction_fr {
	// turn 180 degrees around v_up
	// changes in-direction to out-direction
	transform_x = -transform_x;
	transform_y = 180 + transform_y;
	transform_z = -transform_z;
	// pitch: -s +c
	// yaw:   -s -c
	// roll:  -s +c
	return transform;
}

#if 0
vector(vector transform) anglestransform_turn_direction_fu {
	// turn 180 degrees around v_up
	// changes in-direction to out-direction
	transform_x = -transform_x;
	transform_y = 180 + transform_y;
	transform_z = 180 - transform_z;
	return transform;
}

vector(vector from_transform, vector to_transform) anglestransform_left_divide {
	return anglestransform_multiply(anglestransform_invert(from_transform), to_transform);
}
#endif

vector(vector to_transform, vector from_transform) anglestransform_right_divide {
	return anglestransform_multiply(to_transform, anglestransform_invert(from_transform));
}

vector(vector t, float minimize_roll) anglestransform_normalize {
	float need_flip;
	// first, bring all angles in their range...
	t_x = t_x - 360 * rint(t_x / 360);
	t_y = t_y - 360 * rint(t_y / 360);
	t_z = t_z - 360 * rint(t_z / 360);
	if (minimize_roll)
		need_flip = (t_z > 90 || t_z <= -90);
	else
		need_flip = (t_x > 90 || t_x < -90); // for pitch we prefer to allow exactly -90 degrees for looking straight down

	if (need_flip) {
		if (t_x >= 0) t_x = 180 - t_x; else t_x = -180 - t_x;
		if (t_y > 0) t_y -= 180; else t_y += 180;
		if (t_z > 0) t_z -= 180; else t_z += 180;
	}
	return t;
}

vector(vector t) anglestransform_cancel_roll {
	const float epsilon = 30;
	float f;
	// constraints:
	// forward vector (NOT SO important)
	// right vector, up vector: screen rotation (MORE important)
	// choose best match among all pitch-yaw only rotations
	// FIXME find a better method
	f = fabs(t_x - (-90)) / epsilon;
	if (f < 1) {
		//t_x = -90;
		t_y += t_z;
		t_z = 0;
	} else {
		f = fabs(t_x - 90) / epsilon;
		if (f < 1) {
			//t_x = 90;
			t_y -= t_z;
			t_z = 0;
		}
	}
	return t;
}

vector(vector transform, vector v) anglestransform_apply_to_angles {
	v_x = -v_x;
	v = anglestransform_multiply(transform, v);
	v_x = -v_x;
	return v;
}

vector(vector transform, vector v) anglestransform_apply_to_vangles {
	v = anglestransform_multiply(transform, v);
	return v;
}

vector(vector t0, vector st0, vector t1, vector st1) anglestransform_multiply_get_post_shift {
	// we want the result of:
	//   t0 * (t1 * p + st1) + st0
	//   t0 * t1 * p + t0 * st1 + st0
	return st0 + anglestransform_apply(t0, st1);
}

vector(vector sf, vector t, vector st) anglestransform_pre_post_shift_get_post_shift {
	return st - anglestransform_apply(t, sf);
}
