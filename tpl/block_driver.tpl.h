/**
    @file   %TPL_FILE%.h
    @author %TPL_USER%
    @date   %TPL_DATE%

    @COPYRIGHT (c) SOLECTRIX GmbH, Germany, %TPL_YEAR%, All rights reserved
     The copyright to the document(s) herein is the property of SOLECTRIX GmbH
     The document(s) may be used and/or copied only with the written permission
     from SOLECTRIX GmbH or in accordance with the terms/conditions stipulated
     in the agreement/contract under which the document(s) have been supplied
*/

#ifndef MODULES_%TPL_HEADER_GUARD%_H
#define MODULES_%TPL_HEADER_GUARD%_H

#include "drivers/sx/sfr.h"

#include "os/Types.h"

#include "utils/Compiler/Attributes.h"
#include "utils/lint/lint.h"

/**
 * Block version
 */
%TPL_BLOCK_VERSION%

/**
 * Register offsets
 */
%TPL_REGISTER_OFFSETS%

/**
 * Signal structs and defines
 */
%TPL_SIGNAL_STRUCTS%

/**
 * Register struct and defines
 */
%TPL_REGISTER_STRUCT%

#endif // MODULES_%TPL_HEADER_GUARD%_H
