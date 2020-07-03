$fn = 100;
hgt = 35;
tit = 4;
dia = 13;
module tube() {
    union() {
        %cylinder(h=hgt,d=dia);
        translate( [0,0,hgt]) {
            %sphere(d=dia);
            translate( [0,0,dia/2-tit/2])
                %cylinder(h=tit,r1=1.5,r2=0.5);
        }   
//}
        for( i=[0:30:360]) {
            rotate( [0,0,i])
            translate([4,0,-10])
                color("black")
                cylinder(h=12,d=.4);
        }
    }
}

tube();