
#include "diskey.h"
#include "vfd_control.h"

// blank the display (power settings unchanged)
void vfd_blank() {
  vfd_set_state( VFD_CTRL_BLANK);
  vfd_init();
}

// power down
void vfd_power_down() {
  vfd_set_state( VFD_CTRL_BLANK);
  vfd_clr_state( VFD_CTRL_HV+VFD_CTRL_FIL);
  vfd_init();
}

// power up and unblank
void vfd_power_up() {
  vfd_clr_state( VFD_CTRL_BLANK);
  vfd_set_state( VFD_CTRL_HV+VFD_CTRL_FIL);
  vfd_init();
}

