#!ec-perl
# Unplug content
# Full Environment View: v7
# ectool setProperty /server/unplug/v0 --valueFile fullinventory.pl
# https://flow/commander/pages/unplug/un_run0
my $DEBUG = 0;

# DEBUG: ec-perl fullinventory.pl
#my $XHTML="";$DEBUG= 1;

#my $DEBUG= 1 if not defined $XHTML;
#my $XHTML="" if $DEBUG;
# if ($ENV{'GATEWAY_INTERFACE'}) {
	##Running from unplug
# } else {
	##Debugging outside unplug
	# $DEBUG = 1;
	# my $XHTML = "";
# }

use ElectricCommander;
use strict;
use Data::Dumper;

$| = 1;

my $ec = new ElectricCommander({'format'=>'json'});

my $applications = $ec->getApplications("Default")->{responses}[0];
foreach my $application (@{$applications->{application}}) {
	my $applicationName = $application->{applicationName};
	$XHTML .= qq(
	<h1>Deployments - $applicationName</h1>

	<table class="data" cellspacing="0">
		<tr class="headerRow">
			<td>Environment</td>
			<td>Component</td>
			<td>Artifact</td>
			<td>Version</td>
			<td>Tier</td>
			<td>Completion</td>
			<td>Deploy Process</td>
		</tr>
	);
	
	# Sort environment names according to pipeStage property
	my %environments;
	my $tierMaps = $ec->getTierMaps("Default", $applicationName)->{responses}[0];
	my $pipeStage=1;
	foreach my $tierMap (@{$tierMaps->{tierMap}}) {
		my $environmentName = $tierMap->{environmentName};
		# In case the property doesn't exist
		eval {
			$pipeStage = $ec->getProperty("pipeStage",
				{projectName=>'Default',
				environmentName=>$environmentName})->{responses}[0]->{property}->{value};
			};
		if ($@) {
			$environments{$pipeStage++} = $environmentName;
		} else {
			$environments{$pipeStage} = $environmentName;
		}
	}
	
	my @environments ;
	for my $key ( sort {$a<=>$b} keys %environments) {
		push (@environments, $environments{$key});
	}
	# End of sort
	
	my $envIndex=0;
	my $row="oddRow";
	foreach my $environmentName (@environments) {
	# my $environments = $ec->getEnvironments("Default")->{responses}[0];
	# foreach my $environment (@{$environments->{environment}}) {
		$envIndex++;
		$row = "evenRow" if not $envIndex % 2;
		$row = "oddRow" if $envIndex % 2;
		#my $environmentName = $environment->{environmentName};
		
		my @components;
		my @artifacts;
		my @versions;
		my @tiers;
		my @completionTimes;
		my @applicationIds;
		my @jobIds;
		
		$XHTML .= qq(
		<tr class=\"$row\">
			<td>$environmentName</td>
		);
		
		#<td><a href=\"/commander/plugins/PropertyViewer-1.0.1/view.php?path=/projects/Default/environments/$environmentName\">$environmentName</a></td>

		
		my $environmentInventories = $ec->getEnvironmentInventory("Default",$environmentName, $applicationName)->{responses}[0];
		foreach my $environmentInventory (@{$environmentInventories->{environmentInventory}}) {
			my $componentName=$environmentInventory->{componentName};
			my $artifactName=$environmentInventory->{artifactName};
			my $artifactVersion=$environmentInventory->{artifactVersion};
			my $tierName=$environmentInventory->{tierName};
			my $completionTime=$environmentInventory->{completionTime};
			my $applicationId=$environmentInventory->{applicationId};
			my $jobId=$environmentInventory->{jobId};
			
			push(@components,$componentName);
			push(@artifacts,$artifactName);
			push(@versions,$artifactVersion);
			push(@tiers,$tierName);
			push(@completionTimes,$completionTime);
			push(@applicationIds,$applicationId);
			push(@jobIds,$jobId);
		}
		
		$XHTML .= qq(
			<td>
				<table>
		);
		foreach my $component (@components) {
			$XHTML .= qq(
					<tr>
						<td>$component</td>
					</tr>
			);
		}
		$XHTML .= qq(
				</table>
			</td>
		);
		
		$XHTML .= qq(
			<td>
				<table>
		);	
		foreach my $artifact (@artifacts) {
			$XHTML .= qq(
					<tr>
						<td>$artifact</td>
					</tr>
			);
		}
		$XHTML .= qq(
				</table>
			</td>
		);
		
		$XHTML .= qq(
			<td>
				<table>
		);
		my $index=0;
		foreach my $version (@versions) {
			$XHTML .= qq(
					<tr>
						<td><a href=\"/commander/link/artifactVersionDetails/artifactVersions/@artifacts[$index]:$version\">$version</a></td>
					</tr>
			);
			$index++;
		}
		$XHTML .= qq(
				</table>
			</td>
		);
		
		$XHTML .= qq(
			<td>
				<table>
		);	
		foreach my $tier (@tiers) {
			$XHTML .= qq(
					<tr>
						<td>$tier</td>
					</tr>
			);
		}
		$XHTML .= qq(
				</table>
			</td>
		);
		
		$XHTML .= qq(
			<td>
				<table>
		);
		my $completionTime = @completionTimes[-1]; # last one only
		my $time = $completionTime / 1000;
		my $units = "seconds";
		if ($time > 119) {
			$time = $time/60; $units = "minutes";
			if ($time > 119) {
				$time = $time/60; $units = "hours";
				if ($time > 23) {
					$time = $time/24; $units = "days";
				}
			}
		}
		$time = sprintf("%.1f", $time);
		$XHTML .= qq(
				<tr>
					<td>$time $units ago</td>
				</tr>
		) if ($time > 0);
		$XHTML .= qq(
				</table>
			</td>
		);

		$XHTML .= qq(
			<td>
				<table>
		);
		my $applicationId = @applicationIds[-1]; # last one only
		my $jobId = @jobIds[-1]; # last one only
		$XHTML .= qq(
					<tr>
						<a href=\"/flow/#applications/$applicationId/$jobId/runningProcess">process</a>
					</tr>
		) if ($time > 0);
		$XHTML .= qq(
				</table>
			</td>
		);
		
		$XHTML .= qq(
		</tr>
		);
	}

	$XHTML .= qq(
	</table>
	);
}
#print $XHTML if $DEBUG;