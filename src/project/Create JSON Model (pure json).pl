#!ec-perl
# Unplug content
# JSON Model:  v6

use ElectricCommander;
use strict;
use Data::Dumper;
use JSON;

$| = 1;

my $ecJ = new ElectricCommander({'format'=>'json'});

sub prune {
	my $objects = shift;
	my $toPrune = shift;
		foreach my $object (@{$objects}) {
			foreach my $prune (@{$toPrune}) {
				delete $object->{$prune};
			}
	}
	return $objects;
}

sub descendProperties {
	my $properties = shift;
	
	my $newProperties = ();
	foreach my $property (@{$properties}) {
		if ($property->{propertySheet}) { # a property sheet
			$newProperties->{$property->{propertyName}} = descendProperties($property->{propertySheet}->{property});
		}
		else { # a property
			$newProperties->{$property->{propertyName}} = $property->{value};
		}
	}
	return $newProperties;
}

sub properties {
	my $path=shift;
	
	my $properties;
	$properties = $ecJ->getProperties({'path'=>$path,'expand'=>0,'recurse'=>'true'})->{responses}[0];

	delete $properties->{requestId};
	delete $properties->{propertySheet}->{owner};
	delete $properties->{propertySheet}->{modifyTime};
	delete $properties->{propertySheet}->{propertySheetId};
	delete $properties->{propertySheet}->{lastModifiedBy};
	delete $properties->{propertySheet}->{createTime};
	
	$properties = descendProperties($properties->{propertySheet}->{property});

	return ($properties);
}

sub steps {
	my $project = shift;
	my $application = shift; # Optionally leave blank, "" if component step.
	my $component = shift;  # Leave blank, "" if application step.
	my $process = shift;

	my @steps = ();
	my %args = ();
	%args = (%args, componentName=>$component,) if $component;
	%args = (%args, applicationName=>$application,) if $application;
	my $steps = $ecJ->getProcessSteps($project,$process, \%args)->{responses}[0];
	delete $steps->{requestId};
	foreach my $step (@{$steps->{processStep}}) {
		my %args = (
			projectName=>$project,
			processName=>$process,
			processStepName=>$step->{processStepName},
			);
		%args = (%args, componentName=>$component,) if $component;
		%args = (%args, applicationName=>$application,) if $application;
		my $actualParameters = $ecJ->getActualParameters(\%args)->{responses}[0];
		if (scalar($actualParameters->{actualParameter})) { # Only do this when parameter are present
			delete $actualParameters->{requestId};
			my $parameters = ();
			foreach my $parameter (@{$actualParameters->{actualParameter}}) {
				#$parameter->{value} =~ s/"/\\"/g; # Escape double quotes
				$parameters->{$parameter->{actualParameterName}} = $parameter->{value};
			}
			# my @toPrune = qw(actualParameterId expandable createTime lastModifiedBy modifyTime owner propertySheetId);
			# $step->{parameters} = prune($actualParameters->{actualParameter}, \@toPrune);
			delete $step->{actualParameter};
			$step->{parameters} = $parameters;
		}
		push (@steps, $step);
	}
	my @toPrune = qw(processStepId createTime lastModifiedBy modifyTime owner propertySheetId errorHandling processName subcomponentApplication componentName);
	return prune(\@steps, \@toPrune);
}

sub processes {
	my $project = shift;
	my $application = shift; # Optionally leave blank, "" if component step.
	my $component = shift;  # Leave blank, "" if application step.

	
	my @processes = ();
	my %args = ();
	%args = (%args, componentName=>$component,) if $component;
	%args = (%args, applicationName=>$application,) if $application;
	my $processes = $ecJ->getProcesses($project, \%args)->{responses}[0];
	delete $processes->{requestId};
	foreach my $process (@{$processes->{process}}) {
		# my $dependencies = $ecJ->getProcessDependencies($project, $process->{processName}, \%args)->{responses}[0];
		# foreach my $dependent (@{$dependencies->{processDependency}}) {
			# print Dumper($dependent->{source});
		# }
		$process->{steps} = steps($project,$application,$component,$process->{processName});
		push (@processes, $process);
	}
	my @toPrune = qw(projectName owner propertySheetId applicationId createTime processId modifyTime lastModifiedBy applicationName componentName);
	return prune(\@processes, \@toPrune);
}

sub components {
	my $project = shift;
	
	my $response = $ecJ->getComponents($project)->{responses}[0];
	delete $response->{requestId};
	my @components = ();
	foreach my $component (@{$response->{component}}) {
	# Assuming all components part of application
		$component->{pluginName} =~ s/EC-Artifact-.*/EC-Artifact/;
		$component->{processes} = processes($project, $component->{applicationName}, $component->{componentName});
		my $path = "/projects/Default/";
		$path   .= "applications/$component->{applicationName}/" if ($component->{applicationName});
		$path   .= "components/$component->{componentName}/" ;
		$component->{property}=properties($path);
		push (@components, $component);
	}
	my @toPrune = qw(projectName owner propertySheetId componentId createTime modifyTime lastModifiedBy);
	return prune(\@components, \@toPrune);
	return @components;
}

sub applicationTiers {
	my $project=shift;
	my $application=shift;
	
	my $applicationTiers = $ecJ->getApplicationTiers($project, $application)->{responses}[0];
	my @tiers = ();
	foreach my $applicationTier (@{$applicationTiers->{applicationTier}}) {
		my $components = $ecJ->getComponentsInApplicationTier($project, $application, $applicationTier->{applicationTierName})->{responses}[0];
		my $tier = ();
		my @components = ();
		foreach my $component (@{$components->{component}}) {
			push(@components, $component->{componentName});
		}
		
		$tier->{name} = $applicationTier->{applicationTierName};
		$tier->{components} = [@components];
		push(@tiers, $tier);
	}
	return [@tiers];
}



sub applications {
	my $project = shift;
	
	my $response = $ecJ->getApplications($project)->{responses}[0];
	delete $response->{requestId};
	my @applications = ();
	foreach my $application (@{$response->{application}}) {
		my $processes = processes($project, $application->{applicationName});
		$application->{processes} = $processes;
		#print Dumper($processes);
		#$application->{processes} = $processes;
		#my @procs =  pruneProcesses($processes);
		#print Dumper(@procs);
		my $path = "/projects/Default/";
		$path   .= "applications/$application->{applicationName}/";
		$application->{property}=properties($path);
		
		$application->{tiers}=applicationTiers($project, $application->{applicationName});
		
		$application->{maps}=tierMaps($project, $application->{applicationName});
		# my @map;
		# my $response = $ecJ->getTierMapInApplication($project,$application->{applicationName})->{responses}[0];
					# print Dumper($response);

		# foreach my $map (@{$response->{tierMap}}) {
			# print Dumper($map);
		# }
		# Foreach tier, get component name
		# Tiermaps
		
		push (@applications, $application);
	}
	my @toPrune = qw(owner applicationId propertySheetId modifyTime lastModifiedBy createTime projectName tiermapCount componentCount processCount);
	return prune(\@applications, \@toPrune);
}

sub environments {
	my $project=shift;
	
	my @environments = ();
	my $environments = $ecJ->getEnvironments($project)->{responses}[0];
	foreach my $environment (@{$environments->{environment}}) {
		$environment->{properties}=properties("/projects/$project/environments/$environment->{environmentName}");
		$environment->{tiers}=environmentTiers($project, $environment->{environmentName});
		push (@environments, $environment);
	}
	#delete $environments->{requestId};
	
	my @toPrune = qw(owner environmentId modifyTime lastModifiedBy createTime projectName applicationCount environmentEnabled propertySheetId);
	return prune(\@environments, \@toPrune);
}

sub environmentTiers {
	my $project=shift;
	my $environment=shift;
	
	my @environmentTiers = ();
	my $environmentTiers = $ecJ->getEnvironmentTiers($project, $environment)->{responses}[0];
	foreach my $environmentTier (@{$environmentTiers->{environmentTier}}) {
		#$environment->{property}=properties("/projects/$project/environments/$environment->{environmentName}");
		#push (@environmentTiers, prune(\@environmentTiers, \@toPrune));
		$environmentTier->{resources}=resources($project, $environment, $environmentTier->{environmentTierName})->{resources};
		push (@environmentTiers, $environmentTier);
	}
	#delete $environmentTiers->{requestId};
	my @toPrune = qw(environmentTierId createTime lastModifiedBy modifyTime resourceCount owner projectName propertySheetId environmentName);	
	return prune(\@environmentTiers, \@toPrune);
}

sub resources {
	my $project=shift;
	my $environment=shift;
	my $environmentTier=shift;
	
	my @resources =();
	my $newResources = ();
	my $resources = $ecJ->getResourcesInEnvironmentTier($project, $environment, $environmentTier)->{responses}[0];
	my @toPrune = qw(lastRunTime environmentTierName resourceId agentState hostName hostOS hostPlatform port proxyPort resourceAgentState resourceAgentVersion resourceDisabled stepLimit trusted useSSL environmentName environmentProjectName zoneName createTime lastModifiedBy modifyTime resourceCount owner projectName propertySheetId );	
	foreach my $resource (@{$resources->{resource}}) {
		#$environment->{property}=properties("/projects/$project/environments/$environment->{environmentName}");
		#push (@environmentTiers, prune(\@environmentTiers, \@toPrune));
		push (@resources, $resource->{resourceName});
		
		# prune(\@resources, \@toPrune);
		# print Dumper ($resource->{resourceName});
		
	}
	#delete $environmentTiers->{requestId};
	$newResources->{resources} = [@resources];
	return $newResources;
}

sub tierMaps {
	my $project=shift;
	my $application=shift;
	
	my $response = $ecJ->getTierMaps($project, $application)->{responses}[0];
	my @tierMaps = ();

	foreach my $tierMap (@{$response->{tierMap}}) {
		my $mappings = {};
		foreach my $tierMapping (@{$tierMap->{tierMappings}->{tierMapping}}) {
			my $appTier = $tierMapping->{applicationTierName};
			my $envTier = $tierMapping->{environmentTierName};
			$mappings = {%$mappings, $appTier=>$envTier};
		}
		my $tierMaps = {};
		$tierMaps->{environment} = $tierMap->{environmentName};
		$tierMaps->{mappings} = $mappings;
		push(@tierMaps, $tierMaps);
	}
	return [@tierMaps];
}

sub top {
	my $project=shift;
	
	my $top = ();
	$top->{environments} = environments($project);
	$top->{applications} = applications($project);
	$top->{components} = components($project);
	return $top;
}

use HTML::Entities;
$XHTML .= encode_entities (encode_json top("Default"));

#print encode_json top("Default");

#tierMaps("Default","Sample App");

#Tested
#print encode_json top("Default");
#print encode_json steps("Default","Heat Clinic","","Clean");
#print encode_json steps("Default","Heat Clinic","config","Retrieve config");
#print encode_json processes("Default","Heat Clinic","");
#print encode_json processes("Default","Heat Clinic","warfile");
#print encode_json properties('/projects/Default/applications/Heat Clinic/components/config');
# print encode_json components("Default");
#print encode_json applications("Default");
#print encode_json environments("Default");
#top("Default")
#print encode_json applicationTiers("Default", "Heat Clinic");
#maps("Default", "Heat Clinic");
#print encode_json resources("Default","Broadleaf Prod","Tomcat7");
#print encode_json environmentTiers("Default","Sample App");

#To Test



