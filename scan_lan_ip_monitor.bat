@echo off
setlocal EnableDelayedExpansion

rem scan_lan_ip_monitor.bat
rem -----------------------
rem
rem author: pedro.marques@eibiba.com
rem
rem This script will ping all IP's on a specified LAN to identify which IP addresses are in use by connected devices. 
rem Performing a ping sweep, it will also update the local ARP table, which will be used to get the MAC addresses.
rem Having the list of identified connected devices, the script will loop indefinitely through the identified connected devices list, checking if they are connected or not.
rem To stop the infinite loop, press Ctrl^C and (Y)es.
rem
rem The thread model used in this script was based on Antonio Perez Ayala aka Aacini script (https://stackoverflow.com/a/32413876)

set "debugOutput=0"

rem increase this value for a thourough scan
set /a "scanPingRequests=1"
rem increase this value if you're getting false disconnected devices 
set /a "monitorPingRequests=2"

set "myID=%~2"
if "%~1" neq "" goto %1

set "signal=X"
for /L %%i in (1,1,10) do set "signal=!signal!!signal!"

echo.
echo How this script works
echo =====================
echo Stage 1
echo -------
echo The script will ping all IP's on a specified LAN to identify which IP addresses are in use by connected devices. 
echo Stage 2
echo -------
echo Having the list of identified connected devices, the script will loop indefinitely through the identified connected devices list, checking if they are connected or not.
echo To stop the infinite loop, press Ctrl^^C and (Y)es.
echo ============
echo.
echo Stage 1
echo -------
rem ask for ip of target subnet
set subnet=
for /f "tokens=1,2,3" %%i in ('route print ^| findstr "0.0.0.0"') do (
	if "%%i"=="0.0.0.0" (
		echo %%k |findstr /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" > NUL
		if errorlevel 0 (
			 set subnet=%%k
			 goto skipfor
		)
	)
)
:skipfor

set /P "subnet=Please enter an IP address of the desired LAN [%subnet%]: "
echo.
rem check if IP is valid
echo %subnet% |findstr /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" > NUL
if errorlevel 1 (
    echo Invalid IP subnet.
    goto abort
)
    
for /f "tokens=1,2,3,4 delims=." %%i in ('echo %subnet%') do (
    set oct3=%%i
    set oct2=%%j
    set oct1=%%k
)
set baselist=
set baselistcount=0

echo Retrieving list of current IP addresses in use...

rem Create the list of start commands for the concurrent working threads and start ping scan

set "threads="
del availableThread* 2> NUL

for /L %%i in (1,1,%NUMBER_OF_PROCESSORS%) do (
   set "threads=!threads! & start "" /B cmd /C "%~NX0" Thread %%i"
   > availableThread%%i echo %%i
)

if defined %debugOutput% echo Start of subnet scan
del requestForThread* 2> NUL
( %threads:~3% ) | "%~NX0" Main
if %debugOutput% GTR 0 echo End of subnet scan

echo Done.

for /l %%i in (1,1,254) do (
    set /P "mac=" < macaddr%%i
    if not !mac!==VOID (
        set baselist[!baselistcount!]= %oct3%.%oct2%.%oct1%.%%i, !mac!
        if defined %debugOutput%  echo !mac!
        set /a baselistcount+=1
    )
)
set /a baselistcount-=1

del requestForThread* 2> NUL
del macaddr* 2> NUL

echo.
echo Stage 2
echo -------
set /P "dummyvar=Press <ENTER> to start monitoring for disconnected devices: "

rem monitor loop
:loopmonitor
echo Monitoring... (press Ctrl^^C to stop)
for /l %%A in (0,1,!baselistcount!) do (
    for /f "tokens=1,2  delims=," %%i in ('echo !baselist[%%A]!') do (
        set found /a = 0
        set ipaddr=%%i
        ping -n %monitorPingRequests% -w 200 !ipaddr! | find "TTL=" > NUL
        If errorlevel 1 ( 
				ping -n %monitorPingRequests% -w 200 !ipaddr! | find "TTL=" > NUL
				If errorlevel 1 (
					echo device disconnected: IP: %%i   	MAC: %%j
				)
        )
    )
)

goto loopmonitor


exit /b

:Main

if %debugOutput% GTR 0 echo Main - started

rem Controlling code: process all files and assign each one to available threads
set /a ipsPerThread = (254/%NUMBER_OF_PROCESSORS%)
if (!ipsPerThread*%NUMBER_OF_PROCESSORS%! LSS 254) set /a ipsPerThread += 1
for /L %%f in (1,1,%NUMBER_OF_PROCESSORS%) do (

    call :loop

   rem Assign the next file to the available thread
   echo %%f> requestForThread!nextThread!
   if %debugOutput% GTR 0 echo Main - file "%%f" assigned to thread #!nextThread!

)

if %debugOutput% GTR 0 echo Main - all files sent to processing

rem Wait until all threads ends their tasks
:waitThreadsEnds
set availableThreads=0
for %%t in (availableThread*) do set /A availableThreads+=1
if %availableThreads% lss %NUMBER_OF_PROCESSORS% goto :waitThreadsEnds
for /L %%i in (1,1,%NUMBER_OF_PROCESSORS%) do echo exit> requestForThread%%i
del availableThread* 2> NUL

rem Send "exit" signals to all threads
for /L %%i in (1,1,%numThreads%) do echo exit> requestForThread%%i
if %debugOutput% GTR 0 echo Main - end
goto :EOF

:loop
rem Get the number of next available thread; waits for anyone, if necessary
if not exist availableThread* (
  echo X > mainIsWaiting
  if %debugOutput% GTR 0 echo Main - waiting for an available thread
  set /P availableSignal=
  del mainIsWaiting
)

set "nextThread="
for %%t in (availableThread*) do if not defined nextThread (
  set /P "nextThread=" < %%t
  del %%t
)

if defined nextThread (
    exit /b
)
goto loop

:Thread

rem Wait until a request for this thread appear
if not exist requestForThread%myID% goto Thread
set "request="
set /P "request=" < requestForThread%myID%
if not defined request goto Thread
del requestForThread%myID%
if "%request%" equ "exit" goto :EOF

rem Process the ping command
if %debugOutput% GTR 0 echo %time% - Thread #%myID% start: "%request%" > CON
set /a ipsPerThread = (254/%NUMBER_OF_PROCESSORS%)
if (!ipsPerThread*%NUMBER_OF_PROCESSORS%! LSS 254) set /a ipsPerThread += 1
set /a startBLock=(!request!-1)*!ipsPerThread!+1
set /a endBLock=(!request!)*!ipsPerThread!
if !endBlock! GTR 254 set /a endBlock=254 
for /l %%a in (!startBlock!,1,!endBlock!) do (
	set ipaddr=%oct3%.%oct2%.%oct1%.%%a
	rem echo !ipaddr! > CON
	> macaddr%%a echo VOID
	set macaddr=
	ping !ipaddr! -n %scanPingRequests% -w 2000  | find "TTL=" > NUL
	If not errorlevel 1 (
		for /f "tokens=1,2" %%i in ('arp -a ^| findstr /v "Interface Internet"') do (
			If !ipaddr!==%%i (
				set macaddr=%%j
				> macaddr%%a echo !macaddr!
				echo device found - IP: !ipaddr!  	MAC: !macaddr! > CON
			)
		)
	)
)

if %debugOutput% GTR 0 echo %time% - Thread #%myID% end:   "%request%" > CON

rem Inform that this thread is available for other task
> availableThread%myID% echo %myID%
if exist mainIsWaiting echo %signal:~0,1021%

goto Thread

:abort
exit /b 1
