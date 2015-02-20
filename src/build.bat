@echo off
rem set COMMANDER_SERVER=184.170.225.8
rem set COMMANDER_SERVER=184.170.225.8
rem set COMMANDER_SERVER=cs
set COMMANDER_SERVER=flow
rem set COMMANDER_SERVER=199.204.220.156

ectool --server %COMMANDER_SERVER% login admin changeme

set COMMANDER_HOME=C:\Program Files\Electric Cloud\ElectricCommander
rem set JAVA_HOME=C:\Program Files\Java\jdk1.7.0
set JAVA_HOME=C:\ProgramData\Oracle\Java\javapath
set antPath=C:\Program Files\Electric Cloud\CommanderSDK\tools\ant\bin\ant
"%antPath%" build deploy package.post