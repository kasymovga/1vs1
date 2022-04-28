float(float a) math_safeangle {
    if((a > -361) && (a < 361))
        return a;

    a -= (360 * floor(a / 360));

    return a;
}

float(float ang1,float ang2) math_shortangle_f {
    if(ang1 > ang2) {
        if(ang1 > 180)
            return ang1 - 360;
    } else {
        if(ang1 < -180)
            return ang1 + 360;
    }
    return ang1;
}

vector(vector ang1,vector ang2) math_shortangle_vxy {
    vector vtmp;
    vtmp_x = math_shortangle_f(ang1_x,ang2_x);
    vtmp_y = math_shortangle_f(ang1_y,ang2_y);
    vtmp_z = 0;
    return vtmp;
}
