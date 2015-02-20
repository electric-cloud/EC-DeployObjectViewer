if ($promoteAction eq 'promote') {

	$view->add("Flow Tools",{position=>2});

	my @tabs = (
		"Environments",
		"App-Tiers",
		"App-Processes",
		"Components",
		"Tier Mappings",
		"JSON Model",
		"Full Inventory"
		);

	my $tabIndex = 1;
	foreach (@tabs) {
		$commander->setProperty("/server/unplug/v$tabIndex",'$'."[/plugins/$pluginName/project/unplug/v$tabIndex]",{description=>"Flow $_"});
	    $view->add(["Flow Tools","$_"],{ url => "pages/unplug/un_run${tabIndex}" , position=>$tabIndex });
		$tabIndex++;
	}

	$view->add(["Flow Tools","Flow"],{url => '../flow',position=>10});

	
} elsif ($promoteAction eq 'demote') {
    $view->remove("Flow Tools");
	for (1..7) {
		$commander->setProperty("/server/unplug/v$_",'$'."[/plugins/unplug/project/v_example$_]",{description=>"Content to be displayed by the unplug plugin subpage $_"});
	}
}

