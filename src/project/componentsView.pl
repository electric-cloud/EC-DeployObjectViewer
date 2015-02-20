#!ec-perl
# Unplug content
# Components View:  v4

use HTML::Entities;
use ElectricCommander;
use strict;

$| = 1;

my $ec = new ElectricCommander();

$XHTML .= "<PRE>";
$XHTML .= "\n\n";

$XHTML .=  "App\tComp\tProc\tSteps\tType\tParams\n";
$XHTML .=  "---\t----\t----\t-----\t----\t------\n";

foreach my $application ($ec->getApplications("Default")
		->find("//applicationName")
		->get_nodelist) {
	my $applicationName = $application->string_value;
	$XHTML .=  "<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName\">$applicationName</a>\n";
	foreach my $component ($ec->getComponents("Default",{'applicationName'=>$applicationName})
			->find("//componentName")
			->get_nodelist) {
		my $componentName = $component->string_value;
		#$XHTML .=  "$componentName\n";
		$XHTML .=  "\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName/components/$componentName\">$componentName</a>\n";
				
		foreach my $process ($ec->getProcesses("Default",{'componentName'=>$componentName,'componentApplicationName'=>$applicationName})
				->find("//processName")
				->get_nodelist) {
			my $processName = $process->string_value;
			$XHTML .=  "\t\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName/components/$componentName/processes/$processName\">$processName</a>\n";
			foreach my $step ($ec->getProcessSteps("Default",$processName,{'componentName'=>$componentName,'componentApplicationName'=>$applicationName})
					->find("//processStep")
					->get_nodelist) {
				my $stepName = $step->find("processStepName")->string_value;
				$XHTML .=  "\t\t\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName/components/$componentName/processes/$processName/processSteps/$stepName\">$stepName</a>\n";
				my $stepType = $step->find("subproject")->string_value . "/" . $step->find("subprocedure")->string_value;
				$XHTML .=  "\t\t\t\t$stepType\n";
				foreach my $param ($ec->getActualParameters({
						'projectName'=>"Default",
						'applicationName'=>$applicationName,
						'componentName'=>$componentName,
						'processName'=>$processName,
						'processStepName'=>$stepName
						})
						->find("//actualParameter") # value
						->get_nodelist) {
					my $paramName = $param->find("actualParameterName")->string_value;
					my $value = $param->find("value")->string_value;
					# Make HTML safe
					$value = encode_entities($value);
					$XHTML .=  "\t\t\t\t\t$paramName : \"$value\"\n";
				}
			}
		}
		$XHTML .= "\n";
	}
}
$XHTML .= "</PRE>";