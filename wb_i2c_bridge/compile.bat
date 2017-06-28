@echo off
:: Function   : Compile all sources for module 'i2c_bridge'

set module=wb_i2c_bridge
set lib=rtl_lib

:: Get Current DIR
for %%i in ("%cd%") do set current_dir=%%~nxi

:: IF Current DIR = src we are in the glb_lib
if %current_dir% == src (
  set context=glb_lib
)

:: Check if we are in fpga project context!

if "%context%" == "glb_lib" (
  set ModDir=../../../%lib%/%module%/src
) else (
  set ModDir=../../../src/%lib%/%module%
)
if not "%compile_lib%" == "yes" (
  cd ..\..\..\sim\mti\lib
)

echo Compiling '%module%' to library %lib%.
:: ============================================================================
vcom -work %lib% -just p  %ModDir%/vhdl/*.vhd
vcom -work %lib% -just pb %ModDir%/vhdl/*.vhd
vcom -work %lib% -just e  %ModDir%/vhdl/*.vhd
vcom -work %lib% -just a  %ModDir%/vhdl/*.vhd
:: ============================================================================

:: pause after compilation if batch file was directly called
if not "%compile_lib%" == "yes" ( 
  echo.
  echo *** Compilation completed.
  pause
)
