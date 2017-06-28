/***********************************************************************/
/** I2cBridge.c
 *
 * @Company
 *      solectrix GmbH
 *
 *
 * @File Name
 *      I2cBridge.c
 *
 * @Summary
 *      implementation of the I2cBridge byte access on memory mapped registers
 *
 * @Description
 *      create and init I2cBridge
 *      read and write bytes to memory mapped registers
 *      receive an irq on memory mapped register access failure
 *
 ***********************************************************************/
/***********************************************************************
 * include files
 ***********************************************************************/
#include "I2cBridge.h"
#include "I2cBridgeReg.h"

#include "os/Assertion.h"
#include "os/Types.h"
#include "os/macro.h"
#include "os/Trap.h"
#include "os/IrqHandler.h"
#include "os/irq.h"

#include "utils/lint/lint.h"

#include "project/cms1/Diagnosis/Diagnosis.h"

#include "interrupt_port/src/c/InterruptPort.h"

#include <stdint.h>
#include <stdbool.h>

/***********************************************************************
 * prototypes of local functions
 ***********************************************************************/
static void I2cBridge_SetClkDiv(const I2cBridge_t* const a_pI2cBridge, uint16_t a_clkDiv);
static void I2cBridge_SetDevAddr(const I2cBridge_t* const a_pI2cBridge, uint32_t a_devAddr);
static uint32_t I2cBridge_GetStatus(const I2cBridge_t* const a_pI2cBridge);
static void I2cBridge_ProcessIrq(void);

/***********************************************************************
 * definitions of local variables
 ***********************************************************************/
/* fixme: at the moment we dont know which instance triggers the irq */
/* hack: we use this instance as "singleton" */
static I2cBridge_t* I2c_sInstance = NULL;

/***********************************************************************
 * implementation of global functions
 ***********************************************************************/
/****************************************************/
 /** I2cBridge_Create
 *
 *  \brief creates the module instance by settings the base address
 *
 *  \param [in] a_baseAddress of the modules
 *  \param [in] a_instance container
 *  \param [in] a_interruptId number
 ****************************************************/
void I2cBridge_Create(I2cBridge_t* a_pInstance, uint32_t a_baseAddress, uint32_t a_interruptId)
{
    ASSERT(a_baseAddress != 0U);
    ASSERT(a_pInstance != NULL);
    ASSERT(a_pInstance->ModuleState == MODULESTATE_NOTCREATED);

    a_pInstance->baseAddress = a_baseAddress;
    a_pInstance->interruptId = a_interruptId;
    a_pInstance->ModuleState = MODULESTATE_CREATED;

    I2c_sInstance = a_pInstance;
}

/****************************************************/
/** I2cBridge_Init
 *
 *  \brief Initializes the instance by setting the clock divider, the device address and the irq state
 *
 *  \param [in] a_pI2cBridge pointer to the instance
 *  \param [in] a_clkDiv value of the clock divider
 *  \param [in] a_devAddr value of the device address
 ****************************************************/
void I2cBridge_Init(I2cBridge_t* const a_pI2cBridge, uint16_t a_clkDiv, uint32_t a_devAddr)
{
    ASSERT(a_pI2cBridge != NULL);
    ASSERT(a_pI2cBridge->ModuleState == MODULESTATE_CREATED);

    I2cBridge_SetClkDiv(a_pI2cBridge, a_clkDiv);
    I2cBridge_SetDevAddr(a_pI2cBridge, a_devAddr);

    /* init IRQ */
    IrqHandler_RegisterIsr(a_pI2cBridge->interruptId, I2cBridge_ProcessIrq);
    InterruptPort_Reset(a_pI2cBridge->interruptId);
    InterruptPort_Enable(a_pI2cBridge->interruptId);

    Os_EnableInterrupt(a_pI2cBridge->interruptId);

    a_pI2cBridge->ModuleState = MODULESTATE_OPERATIONAL;
}

/****************************************************/
/** I2cBridge_ReadByte
 *
 *  \brief Read a byte from the memory mapped address
 *
 *  \param [in] a_pI2cBridge pointer to the instance
 *  \param [in] a_pAddress pointer to the address to read
 *  \param [in] a_pValue container will be filled with the read value
 ****************************************************/
void I2cBridge_ReadByte(const I2cBridge_t* const a_pI2cBridge, const uint8_t* const a_pAddress, uint8_t* const a_pValue)
{
    ASSERT(a_pI2cBridge != NULL);
    ASSERT(a_pValue != NULL);
    ASSERT(a_pAddress != NULL);

    /* read byte */
    *a_pValue = *a_pAddress;

    /* if the memory mapped access fails we get an irq */
}

/****************************************************/
/** I2cBridge_WriteByte
 *
 *  \brief Write a byte to the memory mapped address
 *
 *  \param [in] a_pI2cBridge pointer to the instance
 *  \param [in] a_pAddress pointer to the address to write
 *  \param [in] a_value which will be written
 ****************************************************/
void I2cBridge_WriteByte(const I2cBridge_t* const a_pI2cBridge, uint8_t* a_pAddress, uint8_t a_value)
{
    ASSERT(a_pI2cBridge != NULL);
    ASSERT(a_pAddress != NULL);
    /* write byte */
    *a_pAddress = a_value;

    /* if the memory mapped access fails we get an irq */
}

/***********************************************************************
 * implementation of local/helper functions
 ***********************************************************************/
 /****************************************************/
 /** I2cBridge_SetClkDiv
 *
 *  \brief sets the clock divider
 *
 *  \param [in] a_pI2cBridge pointer to the instance
 *  \param [in] a_clkDiv value of the clock divider
 ****************************************************/
static void I2cBridge_SetClkDiv(const I2cBridge_t* const a_pI2cBridge, uint16_t a_clkDiv)
{
    ASSERT(a_pI2cBridge != NULL);
    ASSERT(a_pI2cBridge->ModuleState == MODULESTATE_CREATED);

    WBSCFGI2CBRIDGE_CONFIG_bit(a_pI2cBridge->baseAddress).CLKDIV = a_clkDiv;
}

/****************************************************/
/** I2cBridge_SetDevAddr
 *
 *  \brief sets the device address
 *
 *  \param [in] a_pI2cBridge pointer to the instance
 *  \param [in] a_devAddr value of the device address
 ****************************************************/
static void I2cBridge_SetDevAddr(const I2cBridge_t* const a_pI2cBridge, uint32_t a_devAddr)
{
    ASSERT(a_pI2cBridge != NULL);
    ASSERT(a_pI2cBridge->ModuleState == MODULESTATE_CREATED);

    CHECK_AND_WRITE(WBSCFGI2CBRIDGE_CONFIG_bit(a_pI2cBridge->baseAddress).DEVADDR, a_devAddr,
            WBSCFGI2CBRIDGE_CONFIG_DEVADDR_LENGTH);
}

/****************************************************/
/** I2cBridge_GetStatus
 *
 *  \brief get the instance status flags. Status contains error and success flags.
 *
 *  \param [in] a_pI2cBridge pointer to the instance
 *
 *  \return the instance status flags
 ****************************************************/
static uint32_t I2cBridge_GetStatus(const I2cBridge_t* const a_pI2cBridge)
{
    ASSERT(a_pI2cBridge != NULL);
    ASSERT(a_pI2cBridge->ModuleState == MODULESTATE_OPERATIONAL);

    uint32_t l_Status = WBSCFGI2CBRIDGE_STATUS_REG(a_pI2cBridge->baseAddress).RAW;
    return l_Status;
}

/****************************************************/
/** I2cBridge_ProcessIrq
 *
 *  \brief is called on every interrupt occurrence.
 *      The interrupt occurs on every read or write failure
 *      We set a diagnosis error and trap afterwards.
 ****************************************************/
static void I2cBridge_ProcessIrq(void)
{
    ASSERT(I2c_sInstance != NULL);
    ASSERT(I2c_sInstance->ModuleState == MODULESTATE_OPERATIONAL);

    /* read status register */
    uint32_t l_status = I2cBridge_GetStatus(I2c_sInstance);

    /* set set error with additional information */
    uint8_t l_additionalInfoBuffer[sizeof(l_status)] = {
            (uint8_t) ((l_status >> 24U) & 0xffU),
            (uint8_t) ((l_status >> 16U) & 0xffU),
            (uint8_t) ((l_status >> 8U) & 0xffU),
            (uint8_t) (l_status & 0xffU),
    };
    DiagnosisAdditionalInformation_t l_additinalInfo = {
            .diagnosisErrorId = DIAGNOSIS_I2CTXERROR,
            .length = (uint8_t) sizeof(l_additionalInfoBuffer),
            .pBuffer = l_additionalInfoBuffer,
    };

    Diagnosis_SetErrorWithAdditionalInformation(DIAGNOSIS_I2CTXERROR, &l_additinalInfo);
    SW_TRAP();
}
