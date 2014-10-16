@echo off
:: assumes xsltproc.exe is in %PATH%
:: assumes java is in the %PATH% and saxon9.jar is in the same folder as this batch file
::
::
:: To do: - finish saxon option
::        - update xslt to process more than one first file in %_remainingoptions%
::
setlocal

::default values before parsing arguments with :getopts
set _tagoutput=tags
set _xsltprocessor=xsltproc
set _remainingoptions=
set _quit=
call :getopts %*
if /I "%_quit%" EQU "true" goto :end

if /I %_xsltprocessor% EQU xsltproc goto :xsltproc
if /I %_xsltprocessor% EQU saxon goto :saxon
goto :end

:xsltproc
  :: only designed to process one file with xsltproc
  for /F "usebackq delims=;" %%i in (`echo %_remainingoptions%`) do (
    if /I "%_tagoutput%" EQU "-" (
      xsltproc --stringparam fileName "%_remainingoptions%" "%~dp0\xsl\xsltctags-xsltproc.xsl" "%%i"
    ) else (
      xsltproc --output %_tagoutput% --stringparam fileName "%_remainingoptions%" "%~dp0\xsl\xsltctags-xsltproc.xsl" "%%i"
    )
  )
  goto :end

:saxon
  :: only designed to process one file with saxon
  for /F "usebackq delims=;" %%i in (`echo %_remainingoptions%`) do (
    if /I "%_tagoutput%" EQU "-" (
      java -jar "%~dp0\jars\saxon9.jar" -l:on -versionmsg:off -xsl:"%~dp0\xsl\xsltctags-saxon.xsl" -s:"%%i" fileName="%_remainingoptions%"
    ) else (
      java -jar "%~dp0\jars\saxon9.jar" -l:on -versionmsg:off -xsl:"%~dp0\xsl\xsltctags-saxon.xsl" -s:"%%i" -o:"%_tagoutput%" fileName="%_remainingoptions%"
    )
  )
  goto :end

:create_xsltctagsvim
java -jar "%~dp0\jars\saxon9.jar" -l:on -versionmsg:off -xsl:"%~dp0\xsl\xsltctags-saxon.xsl" -it:createXSLTctagsvim
goto :end

:show_usage
  echo Usage: xsltctags [options] [file]
  echo Options:
  echo   -f tagfile   Use the name specified by tagfile for the tag file
  echo                Default file name is 'tags'
  echo                If tagfile = '-' (without quotes), output will be to stdout
  echo   -o tagfile   Synonym for -f tagfile
  echo   -p [xsltproc^|saxon]  Default is xsltproc
  echo   -v           create file with vim tagbar g:tagbar_type_xslt definition
  echo   -h           Display this usage info
  echo Example Usage:
  echo   xsltctags test.xsl
  echo   --- Processes test.xsl and places output
  echo   --- in to default tagfile named "tags"
  echo.
  echo   xsltctags -f - test.xsl
  echo   --- Processes test.xsl
  echo   --- Output is streamed to stdout
  echo.
  echo   xsltctags -f mytags.txt test.xsl
  echo   --- Processes test.xsl and places output
  echo   --- in mytags.txt
  goto :EOF

:: getargc: Counts the number of arguments passed to it
:getargc
  set argC=0
  for %%x in (%*) do Set /A argC+=1
  goto :eof

::parse the options for xsltctags
:getopts
  :: Remove quotes from _currentoption if they exist. (double and single quotes)
  set _currentoption="'%1'"
  set _currentoption=%_currentoption:"=%
  set _currentoption=%_currentoption:'=%
  set _nextoption="'%2'"
  set _nextoption=%_nextoption:"=%
  set _nextoption=%_nextoption:'=%
  ::no options remaining
  if /I "%_currentoption%" EQU "" (
    call :show_usage
    set _quit=true
    goto :eof  ::return from getopts
  )
  :: is current option -h
  if /I "%_currentoption%" EQU "-h" (
    call :show_usage
    set _quit=true
    goto :eof ::return from getopts
  )
  :: is current option -v
  if /I "%_currentoption%" EQU "-v" (
    call :create_xsltctagsvim
    set _quit=true
    goto :eof ::return from getopts
  )
  :: is current option -f
  if /I "%_currentoption%" EQU "-f" (

    if /I "x%_nextoption%" EQU "x" (
      ::no option passed to -f
      call :show_usage
      set _quit=true
      goto :eof ::return from getopts
    )
    set _tagoutput=%_nextoption%
    REM shift over next option because it has been parsed
    shift
    goto :nextopt ::goes to next option if it exists
    goto :eof ::return from getopts
  )
  :: is current option -o
  if /I "%_currentoption%" EQU "-o" (
    if /I "x%_nextoption%" EQU "x" (
      ::no option passed to -o
      call :show_usage
      goto :eof ::return from getopts
    )
    set _tagoutput=%_nextoption%
    REM shift over next option because it has been parsed
    shift
    goto :nextopt ::goes to next option if it exists
    goto :eof ::return from getopts
  )
  :: is current option -p
  if /I "%_currentoption%" EQU "-p" (

    if /I "x%_nextoption%" EQU "x" (
      ::no option passed to -p
      call :show_usage
      goto :eof ::return from getopts
    )
    set _xsltprocessor=%_nextoption%
    REM shift over next option because it has been parsed
    shift
    goto :nextopt ::goes to next option if it exists
    goto :eof ::return from getopts
  )
  :: Add unknown option to _remainingoptions list
  if /I "%_remainingoptions%" EQU "" (
    set _remainingoptions=%_currentoption%
  ) else (
    set _remainingoptions=%_remainingoptions%;%_currentoption%
  )
  if /I "%_currentoption%" NEQ "" goto :nextopt
  goto :eof
:nextopt
  ::shift over the last option parsed
  shift
  :: Note %1 is now equivalent to %_nextoption%
  if /I "%_nextoption%" NEQ "" (
    echo x%_nextoption% | findstr /r ^x[-] > NUL
    REM Error level == 0 if it begins with -
    REM Otherwise it is 1
    if %errorlevel%==0 (
      REM found a - option, so there are more option(s) to parse
      goto getopts
      goto :eof
    )
  )
  goto :eof

:end
endlocal
