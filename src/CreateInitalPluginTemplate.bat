@echo off
set createPluginPath="C:\Program Files\Electric Cloud\CommanderSDK\tools\scripts\createPlugin.pl"
set pluginPath="c:\Users\gmaxey\se_GMAXEY_9514\se_GMAXEY_9514\internal\gmaxey\WorkingWithCommanderDeployObject\CommanderViews\plugin"
ec-perl %createPluginPath% CGITemplate %pluginPath% "Greg Maxey" "Other" "DeployObjectViewer"