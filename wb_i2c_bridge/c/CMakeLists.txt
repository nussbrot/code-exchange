set(SOURCE
    I2cBridge.c
)

add_library(I2cBridge OBJECT EXCLUDE_FROM_ALL ${SOURCE})
add_pc_lint(I2cBridge ${SOURCE})
