/***********************************************************************/
/** I2cBridge.h
 *
 * @Company
 *      solectrix GmbH
 *
 *
 * @File Name
 *      I2cBridge.h
 *
 * @Summary
 *      implementation of the I2cBridge byte access on memory mapped registers
 *
 * @Description
 *      create and init I2cBridge
 *      read and write bytes to memory mapped registers
 *
 ***********************************************************************/
#ifndef MODULES_WB_I2C_BRIDGE_I2CBRIDGE_H_
#define MODULES_WB_I2C_BRIDGE_I2CBRIDGE_H_

/***********************************************************************
 * include files
 ***********************************************************************/
#include <stdint.h>
#include <stdbool.h>
#include "os/Types.h"

/***********************************************************************
 * type definitions
 ***********************************************************************/
typedef struct
{
    ModuleState_t ModuleState;
    uint32_t baseAddress;
    uint32_t interruptId;
} I2cBridge_t;

/***********************************************************************
 * global functions
 ***********************************************************************/
void I2cBridge_Create(I2cBridge_t* a_pInstance, uint32_t a_baseAddress, uint32_t a_interruptId);
void I2cBridge_Init(I2cBridge_t* const a_pI2cBridge, uint16_t a_clkDiv, uint32_t a_devAddr);

void I2cBridge_ReadByte(const I2cBridge_t* const a_pI2cBridge, const uint8_t* const a_pAddress, uint8_t* const a_pValue);
void I2cBridge_WriteByte(const I2cBridge_t* const a_pI2cBridge, uint8_t* a_pAddress, uint8_t a_value);

#endif /* MODULES_WB_I2C_BRIDGE_I2CBRIDGE_H_ */
