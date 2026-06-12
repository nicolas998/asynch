@echo off
rem Run asynch (built with MSYS2/mingw64) from any Windows terminal.
rem Usage: run-asynch.cmd [-n NUM_PROCS] <global_file.gbl> [extra asynch args]
rem Example: run-asynch.cmd -n 4 examples\clearcreek.gbl

setlocal
set "PATH=C:\msys64\mingw64\bin;C:\Program Files\Microsoft MPI\Bin;%PATH%"
set "ASYNCH_EXE=%~dp0build\src\asynch.exe"

if not exist "%ASYNCH_EXE%" (
    echo asynch.exe not found at %ASYNCH_EXE% - build it first ^(see build\msys-build.sh^).
    exit /b 1
)

set "NPROCS=1"
if /i "%~1"=="-n" (
    set "NPROCS=%~2"
    shift
    shift
)

mpiexec -n %NPROCS% "%ASYNCH_EXE%" %1 %2 %3 %4 %5 %6 %7 %8 %9
endlocal
