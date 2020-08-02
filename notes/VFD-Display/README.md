# VFD display

<table>
  <tr><td><img src="https://github.com/eshazen/retro-25/blob/master/photos/display_11.jpg" width=300>
    <td><img src="https://github.com/eshazen/retro-25/blob/master/hardware/vfd-display/3D/render_board.png" width=300>
    <td><img src="https://github.com/eshazen/retro-25/blob/master/photos/vfd_bare_pcb.jpg" width=300>
</table>

## Progress!

PCB design created under ```hardware/vfd-display```.  Plugs in to display connector on CPU.  Includes 5 HV5812 drivers for 12 digits of VFD, 2 LEDs and 3 jumper/switch/GPIO inputs.  Buffered/latched from the CPU bus.  Ordered from JLCPCB on 7/2/20.  Delivered 7/9/20.  Quick service!

_8/2/20_

Tubes arrived from Kiev after about 5 weeks, but one is missing a pin.  Ordered another batch of 6 so I have some spares.  Assembled the display board and connected to an Arduino for testing.  It works!  Some segments are a bit dim, but at 20V everything seems ok. Power measure below

Voltage | Current | Notes
------- | ------- | -----
  2.5V  |   0.6A  | Filaments (reg to 1.2V)
  5.0V  |   0.03A | Logic (comes from CPU board)
 20.0V  |   0.6A  | Grids
  9.0v  |  ~1.6A  | 1.6A no LEDs, "0.00" = 2.3A, 8's = 3.8A
  
Need a power supply.  Features:  power-up sequence:  (1) 2.5V and 5V(9V) on, delay  (2) 20V on.  Reverse for power-down.  20V should be easily adjustable by the user, and should be controlled by CPU or a timer so it goes off to save the tubes.  After a longer delay the filaments should power down.

Ordered some XL6009 boost modules which should do the job for the 20V.  Would want to add an enable and remote the voltage adjust pot.  Assuming 80% efficiency, need 1.6A at 9V to power, plus CPU at ~1.6A is 3.2A.  Possibly the "2A" 9V converters we have would work, since the VFD display uses about the same power as the LEDs.

Have an LM2586 buck module.  No external enable but looks as if one could unsolder the enable pin and add a wire.

The two LED outputs on the VFD board could be used to control the filament and grid supplies, making for a self-contained unit.

Need to build a breadboard or PCB thing to hold the boost and buck converters and the connectors for power.

## Notes

I've been thinking about a Nixie tube version of an HP calculator
clone for a while, but there are a few problems:  need a 180V power
supply, no decimal point or sign options.

A nice intermediate but still retro option is VFDs, which are very
cheap, 7-segment, include a decimal point and are easier to drive
(they need 20-25V and low-voltage filament power).

I think I can re-use the keyboard part of the keyboard/display,
shearing off the display part (dotted in the drawing) and stack the
CPU board directly below.  There would be a new roughly 200x50mm
display board with (4) HV5812 driver chips.  These are really nice,
having a serial interface and 20 HV output drivers in a friendly DIP28.

The tubes would project vertically up from the new board, which would
be mounted at a nice viewing angle.

There are a few issues:

* Need a 25V supply, but << 1A total current
 * Ordered an MT3806 boost module "free" ship from China.  Also need a buck to provide 2.5V or so for the filaments.  Maybe a PS sequencing circuit, as the HV should come on last and turn off first.
* Need to power the filaments at 1.2V each, 50mA (total 0.6A if parallel,
or 14.4V if series).

Driving the long shift register with 96 segments is easy and could be
done directly by the Z80.

<a href="https://github.com/eshazen/retro-25/blob/master/notes/VFD-Display/new-pcb-top-view.png">
  <img src="https://github.com/eshazen/retro-25/blob/master/notes/VFD-Display/new-pcb-top-view.png" width=200>
  <br>Sketch of the idea</a>
  
