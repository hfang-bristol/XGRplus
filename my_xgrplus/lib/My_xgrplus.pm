package My_xgrplus;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
	my $self = shift;
	
	$ENV{MOJO_REVERSE_PROXY} = 1;
	$self->config(
		hypnotoad => {
			listen  => ['http://*:3010'],
			workers => 8,
			keep_alive_timeout => 300,
			websocket_timeout => 600,
			proxy => 1
		}
	);
	
	# Documentation browser under "/perldoc"
  	$self->plugin('PODRenderer');
  	#$self->plugin('PODViewer');

  	# Router
  	my $r = $self->routes;
	
	# Template names are expected to follow the template.format.handler scheme, with template defaulting to controller/action or the route name, format defaulting to html and handler to ep
	
  	# Normal route to controller
  	## Home
  	$r->get('/')->to(template=>'index', controller=>'action', action=>'index');
  	
  	## XGR+ (and typos)
	$r->get('/XGR+')->to(template=>'index', controller=>'action', action=>'index');
	$r->get('/XGRplus')->to(template=>'index', controller=>'action', action=>'index');
	$r->get('/XGRPLUS')->to(template=>'index', controller=>'action', action=>'index');
	$r->get('/xgrplus')->to(template=>'index', controller=>'action', action=>'index');
	$r->get('/XGR')->to(template=>'index', controller=>'action', action=>'index');
	$r->get('/xgr')->to(template=>'index', controller=>'action', action=>'index');

  	## help
  	$r->get('/XGRplus/help')->to(template=>'XGRplus_help', format=>'html', handler=>'ep', controller=>'action', action=>'index');

	## manual (see Action.pm -> sub booklet -> redirect_to)
	## so that '/dcGO/manual' equivalent to '/dcGObooklet/index.html' (located at my_dcgo/public/dcGObooklet/index.html)
  	$r->get('/dcGO/manual')->to(controller=>'action', action=>'booklet');

  	#############################################
  	## XGR+
  	### EAdomain
	$r->get('/XGRplus/EAdomain')->to(template=>'EAdomain', format=>'html', handler=>'ep', controller=>'action', action=>'EAdomain', post_flag=>0);
	$r->post('/XGRplus/EAdomain')->to(template=>'EAdomain', format=>'html', handler=>'ep', controller=>'action', action=>'EAdomain', post_flag=>1);
	
  	### EAgene
	$r->get('/XGRplus/EAgene')->to(template=>'EAgene', format=>'html', handler=>'ep', controller=>'action', action=>'EAgene', post_flag=>0);
	$r->post('/XGRplus/EAgene')->to(template=>'EAgene', format=>'html', handler=>'ep', controller=>'action', action=>'EAgene', post_flag=>1);
  	
  	### SAgene
	$r->get('/XGRplus/SAgene')->to(template=>'SAgene', format=>'html', handler=>'ep', controller=>'action', action=>'SAgene', post_flag=>0);
	$r->post('/XGRplus/SAgene')->to(template=>'SAgene', format=>'html', handler=>'ep', controller=>'action', action=>'SAgene', post_flag=>1);
	
  	### EAsnp
	$r->get('/XGRplus/EAsnp')->to(template=>'EAsnp', format=>'html', handler=>'ep', controller=>'action', action=>'EAsnp', post_flag=>0);
	$r->post('/XGRplus/EAsnp')->to(template=>'EAsnp', format=>'html', handler=>'ep', controller=>'action', action=>'EAsnp', post_flag=>1);
	
  	### SAsnp
	$r->get('/XGRplus/SAsnp')->to(template=>'SAsnp', format=>'html', handler=>'ep', controller=>'action', action=>'SAsnp', post_flag=>0);
	$r->post('/XGRplus/SAsnp')->to(template=>'SAsnp', format=>'html', handler=>'ep', controller=>'action', action=>'SAsnp', post_flag=>1);
	
  	### EAregion
	$r->get('/XGRplus/EAregion')->to(template=>'EAregion', format=>'html', handler=>'ep', controller=>'action', action=>'EAregion', post_flag=>0);
	$r->post('/XGRplus/EAregion')->to(template=>'EAregion', format=>'html', handler=>'ep', controller=>'action', action=>'EAregion', post_flag=>1);
	
  	### SAregion
	$r->get('/XGRplus/SAregion')->to(template=>'SAregion', format=>'html', handler=>'ep', controller=>'action', action=>'SAregion', post_flag=>0);
	$r->post('/XGRplus/SAregion')->to(template=>'SAregion', format=>'html', handler=>'ep', controller=>'action', action=>'SAregion', post_flag=>1);
	
}

1;

