#!ec-perl
# Unplug content
# Tier Mapping View:  v8

#my $XHTML;

use ElectricCommander;
use strict;
use Data::Dumper;

$| = 1;

my $ec = new ElectricCommander({format=>'json'});

$XHTML .= "<PRE>";
$XHTML .= "\n\n";

$XHTML .=  "Pipeline\tStage\n";
$XHTML .=  "--------\t-----\n";

foreach my $pipelineRun (@{$ec->getPipelineRuntimes()
		->{responses}[0]
		->{flowRuntime}
		}) {
		
	my $flowRuntimeId = $pipelineRun->{flowRuntimeId};
	my $flowRuntimeName = $pipelineRun->{flowRuntimeName};
	my $projectName = $pipelineRun->{projectName};
	
	$XHTML .=  "<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/$projectName/flowRuntimes/$flowRuntimeName\">$flowRuntimeName</a>\n";
	
	foreach my $stage (@{$ec->getPipelineRuntimeDetails({flowRuntimeId=>$flowRuntimeId})
		->{responses}[0]
		->{flowRuntime}[0]
		->{stages}
		->{stage}
		}) {
		my $name = $stage->{name};
		
		# Waiting for API to find stage property sheet
		#$XHTML .=  "\t\t<a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/$projectName/flowRuntimes/$flowRuntimeName/stages/$name\">$name</a>\n";
		$XHTML .=  "\t\t$name\n";
	}
	$XHTML .= "\n";
}
$XHTML .= "</PRE>";

#print $XHTML;