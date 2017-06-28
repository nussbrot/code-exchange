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

#ifndef PLATFORM_%TPL_HEADER_GUARD%_H
#define PLATFORM_%TPL_HEADER_GUARD%_H

/**
 * Wishbone address offset as seen from softcore
 */
#define SOFTCORE_WISHBONE_OFFSET 0x40000000U

/**
 * Module Base Addresses
 */
%TPL_MODULE_ADDRESSES%

#endif // PLATFORM_%TPL_HEADER_GUARD%_H
