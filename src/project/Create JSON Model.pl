#!ec-perl
# Unplug content
# JSON Model:  v6

use ElectricCommander;
use strict;
use Data::Dumper;

$| = 1;

my $ec = new ElectricCommander();

$XHTML .= "<PRE>";
$XHTML .= qq({
);

sub steps {
	my $projectName=shift;
	my $processName=shift;
	my $objectType=shift;
	my $objectName=shift;
	my $applicationName=shift;
	
	my $XHTML="";

	my @steps;
	if ($objectType eq 'applicationName') { # application step
		@steps = $ec->getProcessSteps($projectName,$processName,{'applicationName'=>$objectName})
			->find("//processStep")
			->get_nodelist;
	} else { # component step
		@steps = $ec->getProcessSteps($projectName,$processName,{'componentName'=>$objectName,'applicationName'=>$applicationName})
			->find("//processStep")
			->get_nodelist;
	}
		
		
	if (scalar @steps) {
		$XHTML .= qq(
						"steps": [ );
		foreach my $step (@steps) {
			my $stepName = $step->find("processStepName")->string_value;
			my $subproject = $step->find("subproject")->string_value;
			my $subprocedure = $step->find("subprocedure")->string_value;
			my $subcomponent = $step->find("subcomponent")->string_value;
			my $subcomponentProcess = $step->find("subcomponentProcess")->string_value;
			my $applicationTierName = $step->find("applicationTierName")->string_value;
			
			if ($objectType eq 'applicationName') {
			$XHTML .= qq(
						{
							"processStepName": "$stepName",
							"applicationTierName": "$applicationTierName",);
							} else {
			$XHTML .= qq(
						{
							"name": "$stepName",);							
			}
			
			$XHTML .= qq(
							"subcomponent": "$subcomponent",) if ($subcomponent ne "");
			$XHTML .= qq(						
							"subcomponentProcess": "$subcomponentProcess",) if ($subcomponentProcess ne "");
			$XHTML .= qq(						
							"subproject": "$subproject",) if ($subproject ne "");
			$XHTML .= qq(						
							"subprocedure": "$subprocedure",) if ($subprocedure ne "");
			
			# Parameters
			my @parameters;
		if ($objectType eq 'applicationName') { # application step
			@parameters = $ec->getActualParameters({
				'projectName'=>"Default",
				'applicationName'=>$objectName,
				'processName'=>$processName,
				'processStepName'=>$stepName
				})
				->find("//actualParameter") # value
				->get_nodelist;
		} else { #Component step
			@parameters = $ec->getActualParameters({
				'projectName'=>"Default",
				'componentName'=>$objectName,
				'applicationName'=>$applicationName,
				'processName'=>$processName,
				'processStepName'=>$stepName
				})
				->find("//actualParameter") # value
				->get_nodelist;
		}	
		
			if (scalar @parameters) {
			$XHTML .= qq(
							"parameters": {);	
			
			foreach my $param (@parameters) {
					my $paramName = $param->find("actualParameterName")->string_value;
					my $value = $param->find("value")->string_value;
					$value =~ s/"/\\"/g; # Escape double quotes
					#$value =~ s'\$\['$\['g; # Break up Commander substitution, $[ -> $\[
					$XHTML .= qq(
									"$paramName": "$value",);	
				}
				chop $XHTML; # Get rid of last comma
				$XHTML .= qq(
						},);
				}
				chop $XHTML; # Get rid of last comma
				$XHTML .= qq(
					},);
			}
			chop $XHTML; # Get rid of last comma
			$XHTML .= qq(
			],);
		}
		# chop $XHTML; # Get rid of last comma
		# $XHTML .= qq(
	# },);
	return $XHTML;		
}

sub properties {
	my $path=shift;
	my $XHTML="";
	try {
		my @properties = $ec->getProperties({'path'=>$path,'expand'=>0})
			->find("//property[not(*/self::propertySheetId)]")  # Skip property sheets
			->get_nodelist;
		
		if (scalar @properties) {
		$XHTML .= qq(
				"properties": {);				
			foreach my $property (@properties)
			{
				my $propertyName = $property->find("propertyName")->string_value;
				my $value = $property->find("value")->string_value;
				$value =~ s/"/\\"/g; # Escape double quotes
				#$value =~ s'\$\['$\['g; # Break up Commander substitution, $[ -> $\[
				$XHTML .= qq(
					"$propertyName" : "$value",);
			}
			chop $XHTML;
			$XHTML .= qq(
			},);
		}
	}
	return ($XHTML);
}

# Components
my @components = $ec->getComponents("Default")
		->find("//component")
		->get_nodelist;
		
if (scalar @components) {
	$XHTML .= qq(
	"components": [);

	
	foreach my $component (@components) {
		my $componentName = $component->find("componentName")->string_value;
		my $applicationName = $component->find("applicationName")->string_value;
		
		$XHTML .= qq(
				{
					"name": "$componentName",);
					
		$XHTML .= properties("/projects/Default/applications/$applicationName/components/$componentName");
		
		# Processes
		my @processes = $ec->getProcesses("Default",{'componentName'=>$componentName,'applicationName'=>$applicationName})
			->find("//processName")
			->get_nodelist;
		if (scalar @processes) {
			$XHTML .= qq(
					"processes": [);
			foreach my $process (@processes) {
				my $processName = $process->string_value;
				$XHTML .= qq(
								{
								"name": "$processName",);	
				# Steps
				$XHTML .= steps("Default",$processName,'componentName',$componentName,$applicationName);
				chop $XHTML; # Get rid of last comma
				$XHTML .= qq(
				},);
			}
			chop $XHTML; # Get rid of last comma
			$XHTML .= qq(
						],);
		}
		chop $XHTML; # Get rid of last comma
		$XHTML .= qq(
				},);
	}
	# end Components
	chop $XHTML; # Get rid of last comma
			$XHTML .= qq(
	],);
}

# Environments
my @environments = $ec->getEnvironments("Default")
		->find("//environmentName")
		->get_nodelist;
if (scalar @environments) {
	$XHTML .= qq(
	"environments": [);
	
	
	foreach my $environment (@environments) {
		my $environmentName = $environment->string_value;
		$XHTML .= qq(
			{
				"name": "$environmentName",
				"enabled": "true",);
				
		$XHTML .= properties("/projects/Default/environments/$environmentName");
		# Tiers
		my @tiers = $ec->getEnvironmentTiers("Default",$environmentName)
				->find("//environmentTierName")
				->get_nodelist;
		if (scalar @tiers) {
			$XHTML .= qq(
				"tiers": [);
			
			foreach my $tier (@tiers) {
				my $tierName=$tier->string_value;
				$XHTML .= qq(
					{
						"name": "$tierName",);
				my @resources = $ec->getResourcesInEnvironmentTier("Default",$environmentName,$tierName)
					->find("//resourceName")
					->get_nodelist;
				if (scalar @resources) {
				$XHTML .= qq(
						"resources": [);				
					foreach my $resource (@resources)
					{
						my $resourceName = $resource->string_value;
						$XHTML .= qq(
							"$resourceName",);
					}
					chop $XHTML;
					$XHTML .= qq(
						],);
				}
				chop $XHTML;
				$XHTML .= qq(
					},);
			}
			chop $XHTML; # Get rid of last comma
				$XHTML .= qq(
				],);
		}
		chop $XHTML; # Get rid of last comma
		$XHTML .= qq(
			},);
	}
	chop $XHTML; # Get rid of last comma
			$XHTML .= qq(
	],);
}
	
# Applications
my @applications = $ec->getApplications("Default")
		->find("//applicationName")
		->get_nodelist;
if (scalar @applications) {
	$XHTML .= qq(
	"applications": [);
	foreach my $application (@applications) {
		my $applicationName = $application->string_value;
		$XHTML .= qq(
		{
			"name": "$applicationName",);

		$XHTML .= properties("/projects/Default/applications/$applicationName");
			
		my @tiers = $ec->getApplicationTiers("Default",$applicationName)
				->find("//applicationTierName")
				->get_nodelist;
		if (scalar @tiers) {
		$XHTML .= qq(
			"tiers": [);
			foreach my $tier (@tiers) {
				my $tierName = $tier->string_value;
				$XHTML .= qq(
				{
					"name": "$tierName",);		
				
				my @components = $ec->getComponentsInApplicationTier("Default",$applicationName,$tierName)
							->find("//componentName")
							->get_nodelist;
				if (scalar @components) {
				$XHTML .= qq(
					"components": [);	
					foreach my $component (@components) {
						my $componentName = $component->string_value;
						$XHTML .= qq(
							{
							"name": "$componentName"
							},);
						}
					chop $XHTML; # Get rid of last comma
					$XHTML .= qq(
					],);
					}
					chop $XHTML; # Get rid of last comma
					$XHTML .= qq(
				},);
				}
			chop $XHTML; # Get rid of last comma
			$XHTML .= qq(
			],);
		}
		
		my @processes = $ec->getProcesses("Default",{'applicationName'=>$applicationName})
					->find("//processName")
					->get_nodelist;
		if (scalar @processes) {
			$XHTML .= qq(
				"processes": [);
			foreach my $process (@processes) {
				my $processName = $process->string_value;
				$XHTML .= qq(
				{
					"name": "$processName",);	
				
				$XHTML .= steps("Default",$processName,'applicationName',$applicationName,$applicationName);
				
				# my @steps = $ec->getProcessSteps("Default",$processName,{'applicationName'=>$applicationName})
							# ->find("//processStepName")
							# ->get_nodelist;
				# if (scalar @steps) {
				# $XHTML .= qq(
					# "steps": [ );
					# foreach my $step (@steps) {
						# my $stepName = $step->string_value;
						# my $subproject = $step->find("../subproject")->string_value;
						# my $subprocedure = $step->find("../subprocedure")->string_value;
						# $XHTML .= qq(
							# {
								# "name": "$stepName",
								# "subproject": "$subproject",
								# "subprocedure": "$subprocedure",);
						
						# my @parameters = $ec->getActualParameters({
									# 'projectName'=>"Default",
									# 'applicationName'=>$applicationName,
									# 'processName'=>$processName,
									# 'processStepName'=>$stepName
									# })
									# ->find("//actualParameterName") # value
									# ->get_nodelist;
						# if (scalar @parameters) {
							# $XHTML .= qq(
									# "parameters": {);						
							# foreach my $param (@parameters) {
								# my $paramName = $param->string_value;
								# my $value = $param->find("../value")->string_value;
								# $value =~ s/"/\\"/g; # Escape double quotes
								# $value =~ s'\$\['$\['g; # Break up Commander substitution, $[ -> $\[
								# $XHTML .= qq(
										# "$paramName": "$value",);
							# }
						# chop $XHTML; # Get rid of last comma
						# $XHTML .= qq(
								# },);
						# }
						# chop $XHTML; # Get rid of last comma
						# $XHTML .= qq(
							# },);
					# }
					# chop $XHTML; # Get rid of last comma
					# $XHTML .= qq(
					# ],);
				# }
				chop $XHTML; # Get rid of last comma
				$XHTML .= qq(
				},);
			}
			chop $XHTML; # Get rid of last comma
				$XHTML .= qq(
				],);
		}
		
		my @tierMaps = $ec->getTierMaps("Default",$applicationName)
					->find("//tierMap")
					->get_nodelist;
		if (scalar @tierMaps) {
			$XHTML .= qq(
					"maps": [);
			foreach my $tierMap (@tierMaps) {
				my $mapName = $tierMap->find("tierMapName")->string_value;
				my $envName = $tierMap->find("environmentName")->string_value;
				$XHTML .= qq(
				{
					"environment": "$envName",);	
				
				my @tierMappings = $tierMap
						->find("tierMappings/tierMapping")
						->get_nodelist;
				if (scalar @tierMappings) {
				$XHTML .= qq(
					"mappings": { );	
					foreach my $tierMapping (@tierMappings) {
						my $applicationTierName = $tierMapping->find("applicationTierName")->string_value;
						my $environmentTierName = $tierMapping->find("environmentTierName")->string_value;
								$XHTML .= qq(
							"$applicationTierName": "$environmentTierName",);
					}
					chop $XHTML; # Get rid of last comma
					$XHTML .= qq(
					}
				},);
				}
				#chop $XHTML; # Get rid of last comma
			}
			chop $XHTML; # Get rid of last comma
			$XHTML .= qq(
			],);
		}
		chop $XHTML; # Get rid of last comma
		$XHTML .= qq(
		},);
	}
	chop $XHTML; # Get rid of last comma
		$XHTML .= qq(
	],);
}
chop $XHTML; # Get rid of last comma
$XHTML .= qq(
});
$XHTML .= "</PRE>";