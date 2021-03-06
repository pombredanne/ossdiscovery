@echo off
@setlocal

REM discovery.bat
REM
REM LEGAL NOTICE
REM -------------
REM 
REM OSS Discovery is a tool that finds installed open source software.
REM    Copyright (C) 2007-2009 OpenLogic, Inc.
REM  
REM OSS Discovery is free software: you can redistribute it and/or modify
REM it under the terms of the GNU Affero General Public License version 3 as 
REM published by the Free Software Foundation.  
REM  
REM 
REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM GNU Affero General Public License version 3 (discovery2-client/license/OSSDiscoveryLicense.txt) 
REM for more details.
REM  
REM You should have received a copy of the GNU Affero General Public License along with this program.  
REM If not, see http://www.gnu.org/licenses/
REM  
REM You can learn more about OSSDiscovery, report bugs and get the latest versions at www.ossdiscovery.org.
REM You can contact the OSS Discovery team at info@ossdiscovery.org.
REM You can contact OpenLogic at info@openlogic.com.

set OSSDISCOVERY_HOME=%~dp0%

cd "%OSSDISCOVERY_HOME%"

FOR %%A IN (%*) DO IF /I "%%A" EQU "--help" GOTO HELP
GOTO RUN
:HELP
TYPE help.txt
if exist lib\plugins\census\help.txt type lib\plugins\census\help.txt
if exist lib\plugins\inventory\help.txt type lib\plugins\inventory\help.txt
if exist lib\plugins\olex\help.txt type lib\plugins\olex\help.txt
goto END
:RUN
ruby "%OSSDISCOVERY_HOME%\lib\discovery.rb" --progress 100 --verbose %*

:END

