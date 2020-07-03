# VFD display

<table>
  <tr><td><img src="https://github.com/eshazen/retro-25/blob/master/notes/VFD-Display/vfd-display-stock-photo.jpg" width=300>
    <td><img src="https://github.com/eshazen/retro-25/blob/master/hardware/vfd-display/3D/render_board.png" width=300>
</table>

## Progress!

PCB design created under ```hardware/vfd-display```.  Plugs in to display connector on CPU.  Includes 5 HV5812 drivers for 12 digits of VFD, 2 LEDs and 3 jumper/switch/GPIO inputs.  Buffered/latched from the CPU bus.  Ordered from JLCPCB on 7/2/20.



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
* Need to power the filaments at 1.2V each, 50mA (total 0.6A if parallel,
or 14.4V if series).

Driving the long shift register with 96 segments is easy and could be
done directly by the Z80.

<a href="https://github.com/eshazen/retro-25/blob/master/notes/VFD-Display/new-pcb-top-view.png">
  <img src="https://github.com/eshazen/retro-25/blob/master/notes/VFD-Display/new-pcb-top-view.png" width=200>
  <br>Sketch of the idea</a>
  
