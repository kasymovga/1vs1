.vector moveto;

/**
    Simulate drag
    self.velocity = movelib_vdrag(self.velocity,0.02,0.5);
**/
vector movelib_dragvec(float drag, float exp)
{
    float lspeed,ldrag;

    lspeed = vlen(self.velocity);
    ldrag = lspeed * drag;
    ldrag = ldrag * (drag * exp);
    ldrag = 1 - (ldrag / lspeed);

    return self.velocity * ldrag;
}

/**
    Simulate drag
    self.velocity = movelib_vdrag(somespeed,0.01,0.7);
**/
float movelib_dragflt(float fspeed,float drag,float exp)
{
    float ldrag;

    ldrag = fspeed * drag;
    ldrag = ldrag * ldrag * exp;
    ldrag = 1 - (ldrag / fspeed);

    return ldrag;
}

/**
    Do a inertia simulation based on velocity.
    Basicaly, this allows you to simulate loss of steering with higher speed.
    self.velocity = movelib_inertia_fromspeed(self.velocity,newvel,1000,0.1,0.9);
**/
vector movelib_inertmove_byspeed(vector vel_new, float vel_max,float newmin,float oldmax)
{
    float influense;

    influense = vlen(self.velocity) * (1 / vel_max);

    influense = bound(newmin,influense,oldmax);

    return (vel_new * (1 - influense)) + (self.velocity * influense);
}

vector movelib_inertmove(vector new_vel,float new_bias)
{
    return new_vel * new_bias + self.velocity * (1-new_bias);
}

.float  movelib_lastupdate;
void movelib_move(vector force,float max_velocity,float drag,float mass,float breakforce)
{
    float deltatime;
    float acceleration;
    float mspeed;
    vector breakvec;

    deltatime = time - self.movelib_lastupdate;
    if (deltatime > 0.15) deltatime = 0;
    self.movelib_lastupdate = time;
    if (!deltatime) return;

    mspeed = vlen(self.velocity);

    if (mass)
        acceleration = vlen(force) / mass;
    else
        acceleration = vlen(force);

    if (self.flags & FL_ONGROUND)
    {
        if (breakforce)
        {
            breakvec = (normalize(self.velocity) * (breakforce / mass) * deltatime);
            self.velocity = self.velocity - breakvec;
        }

        self.velocity = self.velocity + force * (acceleration * deltatime);
    }

    if (drag)
        self.velocity = movelib_dragvec(drag, 1);

    if (self.waterlevel > 1)
    {
        self.velocity = self.velocity + force * (acceleration * deltatime);
        self.velocity = self.velocity + '0 0 0.05' * sv_gravity * deltatime;
    }
    else
        self.velocity = self.velocity + '0 0 -1' * sv_gravity * deltatime;

    mspeed = vlen(self.velocity);

    if (max_velocity)
        if (mspeed > max_velocity)
            self.velocity = normalize(self.velocity) * (mspeed - 50);//* max_velocity;
}

/*
.float mass;
.float side_friction;
.float ground_friction;
.float air_friction;
.float water_friction;
.float buoyancy;
float movelib_deltatime;

void movelib_startupdate()
{
    movelib_deltatime = time - self.movelib_lastupdate;

    if (movelib_deltatime > 0.5)
        movelib_deltatime = 0;

    self.movelib_lastupdate = time;
}

void movelib_update(vector dir,float force)
{
    vector acceleration;
    float old_speed;
    float ffriction,v_z;

    vector breakvec;
    vector old_dir;
    vector ggravity;
    vector old;

    if(!movelib_deltatime)
        return;
    v_z = self.velocity_z;
    old_speed    = vlen(self.velocity);
    old_dir      = normalize(self.velocity);

    //ggravity      =  (sv_gravity / self.mass) * '0 0 100';
    acceleration =  (force / self.mass) * dir;
    //acceleration -= old_dir * (old_speed / self.mass);
    acceleration -= ggravity;

    if(self.waterlevel > 1)
    {
        ffriction = self.water_friction;
        acceleration += self.buoyancy * '0 0 1';
    }
    else
        if(self.flags & FL_ONGROUND)
            ffriction = self.ground_friction;
        else
            ffriction = self.air_friction;

    acceleration *= ffriction;
    //self.velocity = self.velocity * (ffriction * movelib_deltatime);
    self.velocity += acceleration * movelib_deltatime;
    self.velocity_z = v_z;

}
*/

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
	mn = '0 0 0';
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
	//print("mn=", vtos(mn), "\n");
	f = (asin(mn * v_forward) / PI) * 180;
	//print("f=", ftos(f), "\n");
	self.angles_x = bound(-45, self.angles_x - bound(-blendrate, f, blendrate), 45);
	f = (asin(mn * v_right) / PI) * 180;
	//print("f=", ftos(f), "\n");
	self.angles_z = bound(-45, self.angles_z + bound(-blendrate, f, blendrate), 45);
}

