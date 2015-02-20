#!ec-perl
# Unplug content
# Application Process View:  v3

use ElectricCommander;
use strict;

$| = 1;

my $ec = new ElectricCommander();

$XHTML .= "<PRE>";
$XHTML .= "\n\n";

$XHTML .=  "App\tProc\tSteps\tType\tParams\n";
$XHTML .=  "---\t----\t-----\t----\t------\n";

foreach my $application ($ec->getApplications("Default")
		->find("//applicationName")
		->get_nodelist) {
	my $applicationName = $application->string_value;
	#$XHTML .=  "$applicationName\n";
	$XHTML .=  "<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName\">$applicationName</a>\n";
			
	foreach my $process ($ec->getProcesses("Default",{'applicationName'=>$applicationName})
			->find("//processName")
			->get_nodelist) {
		my $processName = $process->string_value;
		$XHTML .=  "\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName/processes/$processName\">$processName</a>\n";
		foreach my $step ($ec->getProcessSteps("Default",$processName,{'applicationName'=>$applicationName})
				->find("//processStepName")
				->get_nodelist) {
			my $stepName = $step->string_value;
			$XHTML .=  "\t\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName/processes/$processName/processSteps/$stepName\">$stepName</a>\n";
			my $stepType = $step->find("../subprocedure")->string_value;
			$XHTML .=  "\t\t\t$stepType\n";

			foreach my $param ($ec->getActualParameters({
					'projectName'=>"Default",
					'applicationName'=>$applicationName,
					'processName'=>$processName,
					'processStepName'=>$stepName
					})
					->find("//actualParameterName") # value
					->get_nodelist) {
				my $paramName = $param->string_value;
				my $value = $param->find("../value")->string_value;
				$XHTML .=  "\t\t\t\t$paramName : \"$value\"\n";

			}
		}
	}
	$XHTML .= "\n";
}
$XHTML .= "</PRE>";