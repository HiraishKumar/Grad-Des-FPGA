@echo off

REM Define variables for the target and source files.
set TARGET=Top_tb
set VCS_FILES=Top.v Top_tb.v
set LIB_PATH=include

if "%1" == "clean" goto clean
if "%1" == "run" goto run
if "%1" == "wave" goto wave
if "%1" == "test" goto test
goto all

:compile
    iverilog -g2012 -o %TARGET%.out -y %LIB_PATH% %VCS_FILES%
    if errorlevel 1 (
        echo Compilation failed.
        exit /b 1
    )
    goto end

:all
    call :compile
    if errorlevel 1 exit /b 1
    call :run
    if errorlevel 1 exit /b 1
    call :wave
    if errorlevel 1 exit /b 1
    goto end

:test
    python PythonTests/GradientDescent.py
    if errorlevel 1(
        echo Could Not Run Python test
        exit /b 1
    )
    goto end


:run
    vvp %TARGET%.out
    if errorlevel 1 (
        echo Simulation failed.
        exit /b 1
    )
    goto end

:wave
    gtkwave %TARGET%.vcd -a %TARGET%.gtkw
    if errorlevel 1 (
        echo GTKWave failed.
        exit /b 1
    )
    goto end

:clean
    del %TARGET%.out %TARGET%.vcd >nul 2>nul
    if errorlevel 1 (
        echo Clean failed, some files may not have been found.
    ) else (
        echo Clean successful.
    )
    goto end

:end
    echo Done.
