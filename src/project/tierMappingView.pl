#!ec-perl
# Unplug content
# Tier Mapping View:  v5

use ElectricCommander;
use strict;

$| = 1;

my $ec = new ElectricCommander();

$XHTML .= "<PRE>";
$XHTML .= "\n\n";

$XHTML .=  "App\tMap\tEnv\tTiers (App->Env)\n";
$XHTML .=  "---\t---\t---\t----------------\n";

foreach my $application ($ec->getApplications("Default")
		->find("//applicationName")
		->get_nodelist) {
	my $applicationName = $application->string_value;
	#$XHTML .=  "$applicationName\n";
	$XHTML .=  "<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName\">$applicationName</a>\n";
			
	foreach my $tierMap ($ec->getTierMaps("Default",$applicationName)
			->find("//tierMap")
			->get_nodelist) {
		my $mapName = $tierMap->find("tierMapName")->string_value;
		my $envName = $tierMap->find("environmentName")->string_value;
		$XHTML .=  "\t$mapName\n";
		$XHTML .=  "\t\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/environments/$envName\">$envName</a>\n";
		
		foreach my $tierMapping ($tierMap
				->find("tierMappings/tierMapping")
				->get_nodelist) {
			my $tierMappingName = $tierMapping->find("tierMappingName")->string_value;
			$XHTML .=  "\t\t\t$tierMappingName\n";
		}
	}
	$XHTML .= "\n";
}
$XHTML .= "</PRE>";