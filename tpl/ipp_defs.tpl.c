/**
    @file   ipp_defs.c
    @author %TPL_USER%
    @date   %TPL_DATE%

    Mekra HDR60 IPP register definitions 
    @COPYRIGHT (c) SOLECTRIX GmbH, Germany, %TPL_YEAR%            All rights reserved
     The copyright to the document(s) herein is the property of SOLECTRIX GmbH
     The document(s) may be used and/or copied only with the written permission
     from SOLECTRIX GmbH or in accordance with the terms/conditions stipulated
     in the agreement/contract under which the document(s) have been supplied
*/

#include "ipp_defs.h"


/* 
 * Signals 
 */
SignalStruct SignalMap[] = {
%TPL_REGISTERMAP%
}; //SignalMap end

uint32_t readWBRegister(uint32_t idx)
{
	//check if idx is valid
	if(idx > sizeof(SignalMap)/sizeof(SignalMap[0]))
	{
		//index not valid
		return -1;
	}
	switch (SignalMap[idx].width)
	{
		case BYTE:
			return (*(volatile uint8_t*)((SignalMap[idx].address) | PLASMA_FPGA_OFFSET));
			break;
		case WORD:
			return (*(volatile uint16_t*)((SignalMap[idx].address) | PLASMA_FPGA_OFFSET));
			break;
		case DWORD:
			return (*(volatile uint32_t*)((SignalMap[idx].address) | PLASMA_FPGA_OFFSET));
			break;
		}
	//should never be reached
	return -1;
}

void writeWBRegister(uint32_t idx, uint32_t value)
{
	//check if idx is valid
	if(idx > sizeof(SignalMap)/sizeof(SignalMap[0]))
	{
		//index not valid
		return;
	}
	switch (SignalMap[idx].width)
	{
		case BYTE:
			(*(volatile uint8_t*)((SignalMap[idx].address) | PLASMA_FPGA_OFFSET)) = (uint8_t)(value);
			break;
		case WORD:
			(*(volatile uint16_t*)((SignalMap[idx].address) | PLASMA_FPGA_OFFSET)) = (uint16_t)(value);
			break;
		case DWORD:
			(*(volatile uint32_t*)((SignalMap[idx].address) | PLASMA_FPGA_OFFSET)) = (uint32_t)(value);
			break;
	}
	//should never be reached
	return;
}

uint32_t readWBSignal(uint32_t idx)
{
  uint32_t reg = readWBRegister(idx);
  uint32_t shift = SignalMap[idx].shift;
  uint32_t mask = SignalMap[idx].mask << shift;
  return ((reg & mask) >> shift);
}

void writeWBSignal(uint32_t idx, uint32_t value)
{
  // for Signal based writing, read/modify/write is the only option
  uint32_t reg = readWBRegister(idx);
  uint32_t shift = SignalMap[idx].shift;
  uint32_t mask = SignalMap[idx].mask << shift;
  
  uint32_t result = (reg & (~mask)) | ((value << shift) & mask);
  writeWBRegister(idx, result);
}


