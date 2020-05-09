
//
// UMON entry points
//

#define UMON_ORG 8100H

#define  UMON_main       UMON_ORG+00H  // cold start
#define  UMON_getch      UMON_ORG+03H  // read serial input to HL [C]
#define  UMON_putch      UMON_ORG+06H  // output serial from HL [C]
#define  UMON_crlf       UMON_ORG+09H  // output CR/LF
#define  UMON_puts       UMON_ORG+0cH  // output string from HL
#define  UMON_phex2      UMON_ORG+0fH  // output hex byte from A
#define  UMON_phex4      UMON_ORG+12H  // output hex word from HL
#define  UMON_setpzero   UMON_ORG+15H  // set pzero mask from A
#define  UMON_updpzero   UMON_ORG+18H  // update port from pzero
#define  UMON_kbscan     UMON_ORG+1bH  // scan keyboard to HL
#define  UMON_display    UMON_ORG+1eH  // update display from HL
