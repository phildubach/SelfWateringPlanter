// Self Watering Planter
// MIT License
// Copyright (c) 2021 Phil Dubach

TYPE = "OUTER"; // [OUTER, INNER, COMBINED]
OUTER = [100, 100, 90];
WALL = 2;
TOP_H = 10;
BOTTOM_H = 30;
FILLER = 20;
RADIUS = 10;
GAP = 0.2;
INSET = 25;
SPACING = 6;
HOLES = 2;
CROSS_SECTION = false;

$fn = $preview ? 16 : 64;

EPS = 0.01;

module cut_sphere(r, b) {
    intersection() {
        translate([-r,-r,-b]) cube([2*r,2*r,b+r]);
        sphere(r);
    }
}

/* Sort of rounded cube */
module sorcube(dim, r, angle=45) {
    b = cos(angle) * r;
    hull() for (x = [r ,dim.x-r]) for (y = [r, dim.y-r]) {
        translate([x,y,b]) {
            cut_sphere(r,b);
            cylinder(r=r, h=dim.z-b);
        }
    }
}

module outer_shell(dim, wall, r) {
    difference() {
        sorcube(dim, r);
        translate([wall,wall,wall]) sorcube(dim-[2*wall,2*wall,wall-EPS], r-wall);
    }    
}

module round_rect(x, y, r) {
    hull() for (cx = [r, x-r]) for (cy = [r, y-r]) translate([cx,cy]) circle(r=r);
}

module cutoff(r, a) {
    rotate([0,0,a]) difference() {
        square([r, r]);
        translate([r,r]) circle(r);
    }
}

module filler(ro, ri) {
    f = FILLER + WALL + GAP;
    difference() {
        square([f,f]);
        translate([f,f]) cutoff(ri, 180);
    }
    translate([f-EPS,0]) cutoff(ro,0);
    translate([0,f-EPS]) cutoff(ro,0);
}

module inner_shape(dim, ro, ri, top_h, bottom_h) {
    difference() {
        union() {
            
            hull() translate([WALL+GAP,WALL+GAP,0]) {
                // main vertical shell
                translate([0,0,bottom_h+INSET])
                    linear_extrude(dim.z-bottom_h-INSET-top_h) 
                        round_rect(dim.x, dim.y, ro);
                // basket footprint
                translate([INSET,INSET,bottom_h]) linear_extrude(INSET)
                    round_rect(dim.x-2*INSET, dim.y-2*INSET, ro);
            }
            hull() {
                translate([0,0,dim.z-top_h+WALL+GAP])
                    linear_extrude(top_h-WALL-GAP) 
                        round_rect(dim.x+2*(GAP+WALL), dim.y+2*(GAP+WALL), ro+GAP+WALL);
                translate([GAP+WALL,GAP+WALL,dim.z-top_h-EPS]) linear_extrude(WALL)
                    round_rect(dim.x, dim.y, ro+GAP+WALL);
            }
        }
        translate([-WALL-GAP-EPS,-WALL-GAP-EPS,-EPS]) linear_extrude(dim.z+top_h+2*EPS) {
            filler(ro,ri);
        }
    }
    // basket
    translate([WALL+GAP+INSET,WALL+GAP+INSET,0]) linear_extrude(bottom_h+EPS)
        round_rect(dim.x-2*INSET, dim.y-2*INSET, ro);
}

module inner_shell(dim, wall, r, top_h, bottom_h) {
    do = dim-[2*(WALL+GAP),2*(WALL+GAP),WALL+GAP-top_h];
    di = do - [2*WALL,2*WALL,WALL];
    difference() {
        translate([0,0,WALL+GAP]) {
            difference() {
                inner_shape(do, r-WALL-GAP, r-WALL-GAP, top_h, bottom_h);
                translate([WALL,WALL,WALL+EPS])
                    inner_shape(di, r-2*WALL-GAP, r-GAP,
                        top_h-WALL*(sqrt(2)-1)/2,
                        bottom_h+WALL*(sqrt(2)-3)/2);
            }
        }
        for (dz = [0:SPACING:bottom_h-3*WALL-sqrt(2)*HOLES]) {
            qx = do.x/2-INSET-(r-WALL-GAP)-sqrt(2)*HOLES/2;
            translate([dim.x/2,dim.y/2,3*WALL+GAP+sqrt(2)*HOLES/2]) for (dx = [0:SPACING:qx]) {
                translate([dx,0,dz]) rotate([0,45,0]) cube([HOLES,dim.y+2*EPS,HOLES],center=true);
                translate([-dx,0,dz]) rotate([0,45,0]) cube([HOLES,dim.y+2*EPS,HOLES],center=true);
            }
            qy = do.y/2-INSET-(r-WALL-GAP)-sqrt(2)*HOLES/2;
            translate([dim.x/2,dim.y/2,3*WALL+GAP+sqrt(2)*HOLES/2]) for (dy = [0:SPACING:qy]) {
                translate([0,dy,dz]) rotate([45,0,0]) cube([dim.x+2*EPS,HOLES,HOLES],center=true);
                translate([0,-dy,dz]) rotate([45,0,0]) cube([dim.x+2*EPS,HOLES,HOLES],center=true);
            }
        }
    }
}

difference() {
    union() {
        if (TYPE == "OUTER" || TYPE == "COMBINED") 
            outer_shell(OUTER, WALL, RADIUS);
        if (TYPE == "INNER" || TYPE == "COMBINED") 
            inner_shell(OUTER, WALL, RADIUS, TOP_H, BOTTOM_H);
    }
    if (CROSS_SECTION) translate([-EPS,-EPS,-EPS]) cube(OUTER+[-OUTER.x/2,-OUTER.y/2,2*EPS+TOP_H]);
}

