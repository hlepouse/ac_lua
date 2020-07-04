@rem B.Komazec Setting environment for using Microsoft Visual Studio 2010 x86/x64 tools.
@echo off

@if "%1"=="x86" goto set_x86
@if "%1"=="x64" goto set_x64
@if "%1"=="" goto error

:set_x86
@echo Setting environment for using Microsoft Visual Studio 2010 x86 tools.

set INCLUDE=^
c:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\include;^
c:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\include;

set LIB=^
c:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\lib;^
c:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\lib;

set PATH=^
%SystemRoot%\system32;^
c:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin;^
c:\program files (x86)\microsoft visual studio 10.0\common7\ide;

goto test_bin_locations

:set_x64
@echo Setting environment for using Microsoft Visual Studio 2010 x64 tools.

set INCLUDE=^
c:\Program Files\Microsoft Visual Studio 10.0\VC\include;^
c:\Program Files\Microsoft SDKs\Windows\v7.0A\include;

set LIB=^
c:\Program Files\Microsoft Visual Studio 10.0\VC\lib\amd64;^
c:\Program Files\Microsoft SDKs\Windows\v7.0A\lib\x64;

set PATH=^
%SystemRoot%\system32;^
C:\Program Files\Microsoft Visual Studio 10.0\VC\bin\x86_amd64;^
C:\Program Files\Microsoft Visual Studio 10.0\VC\bin;^
C:\Program Files\Microsoft Visual Studio 10.0\Common7\ide;

goto test_bin_locations

:test_bin_locations
@echo on
where nmake
where cl.exe
where link.exe
@echo off
goto:eof

:error
@echo Usage: setenv.bat [x86^|x64]

goto:eof