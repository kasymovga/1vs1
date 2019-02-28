void movelib_move_simple(vector newdir,float velo,float blendrate)
{
    self.velocity = self.velocity * (1 - blendrate) + (newdir * blendrate) * velo;
}
void movelib_beak_simple(float force)
{
    float mspeed;
    vector mdir;
    float vz;

    mspeed = max(0,vlen(self.velocity) - force);
    mdir   = normalize(self.velocity);
    vz = self.velocity_z;
    self.velocity = mdir * mspeed;
    self.velocity_z = vz;
}

void movelib_groundalign4point(float spring_length,float spring_up,float blendrate)
{
	vector v, vx, vy, vz, v1, mn, vcross1, vcross2;
	float f;
	v = self.origin;
	//v_z += self.mins_z * 0.5;
	vx = '1 0 0' * spring_length;
	vy = '0 1 0' * spring_length;
	vz = '0 0 1' * spring_up;
	blendrate = 90 * blendrate * frametime;
	
	v1 = v + vy;
	traceline(v1, v1 - vz, MOVE_NORMAL, self);
	vcross1 = (trace_startsolid ? v1 : trace_endpos);

	v1 = v - vy;
	traceline(v1, v1 - vz, MOVE_NORMAL, self);
	vcross1 -= (trace_startsolid ? v1 : trace_endpos);

	v1 = v + vx;
	traceline(v1, v1 - vz, MOVE_NORMAL, self);
	vcross2 = (trace_startsolid ? v1 : trace_endpos);

	v1 = v - vx;
	traceline(v1, v1 - vz, MOVE_NORMAL, self);
	vcross2 -= (trace_startsolid ? v1 : trace_endpos);

	mn = normalize(cross(vcross2, vcross1));
	f = asin(mn * v_forward) * RAD2DEG;
	self.angles_x = bound(-45, self.angles_x - bound(-blendrate, f, blendrate), 45);
	f = asin(mn * v_right) * RAD2DEG;
	self.angles_z = bound(-45, self.angles_z + bound(-blendrate, f, blendrate), 45);
}

