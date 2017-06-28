/**
    @file   ipp_defs.h
    @author %TPL_USER%
    @date   %TPL_DATE%

    Mekra HDR60 IPP register definitions
    @COPYRIGHT (c) SOLECTRIX GmbH, Germany, %TPL_YEAR%            All rights reserved
     The copyright to the document(s) herein is the property of SOLECTRIX GmbH
     The document(s) may be used and/or copied only with the written permission
     from SOLECTRIX GmbH or in accordance with the terms/conditions stipulated
     in the agreement/contract under which the document(s) have been supplied
*/

#ifndef IPP_DEFS_H
#define IPP_DEFS_H

#include <stdint.h>

#define PLASMA_FPGA_OFFSET 0x80000000

/** 
 * Offsets
 */
%TPL_OFFSETS%


enum bitWidth {
  BYTE = 0,
  WORD = 1,
  DWORD = 2,
};

/** 
 * Register Signals 
 */
enum SigIdx {
  %TPL_SIGNAMES%
}; //enum ends


/** 
 * Register Signal Values
 */
%TPL_ENUMVALUES%


// struct
typedef struct {
  char* name;
  uint32_t address;
  uint32_t mask;
  uint8_t  shift;
  uint8_t  width;
  char* desc;
} SignalStruct; //struct end


// prototypes
void      writeWBRegister(uint32_t idx, uint32_t value);
uint32_t  readWBRegister(uint32_t idx);
void      writeWBSignal(uint32_t idx, uint32_t value);
uint32_t  readWBSignal(uint32_t idx);

extern SignalStruct SignalMap[];


#endif /* IPP_DEFS_H */
