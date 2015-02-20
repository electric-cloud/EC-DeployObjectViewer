#!ec-perl
# Unplug content
# Application Tier View:  v2

use HTML::Entities;
use ElectricCommander;
use strict;

$| = 1;

my $ec = new ElectricCommander();

$XHTML .= "<PRE>";
$XHTML .= "\n\n";

$XHTML .=  "App\tTier\tComp\tProc\tSteps\tType\tParams\n";
$XHTML .=  "---\t----\t----\t----\t-----\t----\t------\n";

foreach my $application ($ec->getApplications("Default")
		->find("//applicationName")
		->get_nodelist) {
	my $applicationName = $application->string_value;
	#$XHTML .=  "$applicationName\n";
	$XHTML .=  "<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName\">$applicationName</a>\n";
	foreach my $tier ($ec->getApplicationTiers("Default",$applicationName)
			->find("//applicationTierName")
			->get_nodelist) {
		my $tierName = $tier->string_value;
		#$XHTML .=  "\t$processName\n";
		$XHTML .=  "\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName/applicationTiers/$tierName\">$tierName</a>\n";

		foreach my $component ($ec->getComponentsInApplicationTier("Default",$applicationName,$tierName)
				->find("//componentName")
				->get_nodelist) {
			my $componentName = $component->string_value;
			#$XHTML .=  "\t\t$processStepName\n";
			$XHTML .=  "\t\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName/components/$componentName\">$componentName</a>\n";
			
			foreach my $process ($ec->getProcesses("Default",{'componentName'=>$componentName,'applicationName'=>$applicationName})
					->find("//processName")
					->get_nodelist) {
				my $processName = $process->string_value;
				#$XHTML .=  "\t\t$processStepName\n";
				$XHTML .=  "\t\t\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/components/$componentName/processes/$processName\">$processName</a>\n";
				foreach my $step ($ec->getProcessSteps("Default",$processName,{'componentName'=>$componentName,'applicationName'=>$applicationName})
						->find("//processStepName")
						->get_nodelist) {
					my $stepName = $step->string_value;
					$XHTML .=  "\t\t\t\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/applications/$applicationName/components/$componentName/processes/$processName/processSteps/$stepName\">$stepName</a>\n";
					my $stepType = $step->find("../subprocedure")->string_value;
					$XHTML .=  "\t\t\t\t\t$stepType\n";

					foreach my $param ($ec->getActualParameters({
							'projectName'=>"Default",
							'componentName'=>$componentName,
							'applicationName'=>$applicationName,
							'processName'=>$processName,
							'processStepName'=>$stepName
							})
							->find("//actualParameterName") # value
							->get_nodelist) {
						my $paramName = $param->string_value;
						my $value = $param->find("../value")->string_value;
						# Make HTML safe
						$value = encode_entities($value);
						$XHTML .=  "\t\t\t\t\t\t$paramName : \"$value\"\n";

					}
				}
			}
		}
	}
	$XHTML .= "\n";
}
$XHTML .= "</PRE>";
