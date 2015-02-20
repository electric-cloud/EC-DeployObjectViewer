#!ec-perl
# Unplug content
# Environment View:  v1

use ElectricCommander;
use strict;

$| = 1;

my $ec = new ElectricCommander();

$XHTML .= "<PRE>";
$XHTML .=  "Env\tTier\tResources\n";
$XHTML .=  "---\t----\t---------\n";

foreach my $environment ($ec->getEnvironments("Default")
		->find("//environmentName")
		->get_nodelist) {
	my $environmentName = $environment->string_value;
	$XHTML .=  "<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/environments/$environmentName\">$environmentName</a>\n";
	foreach my $tier ($ec->getEnvironmentTiers("Default",$environmentName)
		->find("//environmentTierName")
		->get_nodelist) {
		my $tierName=$tier->string_value;
		#$XHTML .=  "\t$tierName\n";
		$XHTML .=  "\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/environments/$environmentName/environmentTiers/$tierName\">$tierName</a>\n";

		foreach my $resource ($ec->getResourcesInEnvironmentTier("Default",$environmentName,$tierName)
			->find("//resourceName")
			->get_nodelist) {
			my $resourceName = $resource->string_value;
			#$XHTML .=  "\t\t$resourceName\n";
			#https://184.170.225.8/commander/link/resources?s=Cloud#rd;resourceName=AcmeApp_PROD_AP_DB_machine28
			$XHTML .=  "\t\t<a href=\"/commander/link/resources?s=Cloud#rd;resourceName=$resourceName\">$resourceName</a>\n";
			# my $versionField= $ec->getProperty("/resources/$resourceName/AcmeApp_${tierName}_packageVersion")
				# ->find("//value");
			# foreach my $version (split("\n",$versionField)) {
				# my @versionAndLink=split(",",$version);
				# my $version= $versionAndLink[0];
				# my $workflowName=$versionAndLink[1];
				# $XHTML .=  "\t\t\t$version\n";

			# }
		}
	}
	$XHTML .= "\n";
}
$XHTML .= "</PRE>";

