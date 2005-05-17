#!/usr/bin/perl

use Module::Build;
my $build = Module::Build->new
  (
   module_name => 'IO::Pipe::Producer',
   license     => 'perl',
   requires    => {'perl'     => '5.8.1',
		   'IO::Pipe' => '>= 1.122'},
  );
$build->create_build_script;
