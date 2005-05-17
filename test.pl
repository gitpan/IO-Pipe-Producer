#!/usr/bin/perl

use strict;

#Print the number of tests in a format that Module::Build understands
print("1..6\n");

#Initialize vars needed by IO::Pipe::Producer
my $subroutine_reference = \&test;
my @subroutine_parameters = ('testing',1,2,3);

#Keep track of how many tests failed
my $num_failed = 0;

#use the module I want to test
use IO::Pipe::Producer;

##
## Test 1
##

#Test a scalar context call to getSubroutineProducer
my $obj = new IO::Pipe::Producer();
my $stdout_fh =
  $obj->getSubroutineProducer($subroutine_reference,@subroutine_parameters);
my @output = map {chomp;$_} <$stdout_fh>;

if(equaleq(\@subroutine_parameters,\@output))
  {print("ok 1\n")}
else
  {
    $num_failed++;
    print("not ok 1\n");
  }

##
## Test 2
##

#Test a list context call to getSubroutineProducer
$obj = new IO::Pipe::Producer();
my($stderr_fh);
($stdout_fh,$stderr_fh) =
  $obj->getSubroutineProducer($subroutine_reference,@subroutine_parameters);
@output          = map {chomp;$_} <$stdout_fh>;
my @error_output = map {chomp;$_} <$stderr_fh>;

if(equaleq(\@subroutine_parameters,\@output) &&
   equaleq(\@subroutine_parameters,\@error_output))
  {print("ok 2\n")}
else
  {
    $num_failed++;
    print("not ok 2\n");
  }

##
## Test 3
##

#Test a scalar context call to new that returns an STDOUT handle
$stdout_fh = new IO::Pipe::Producer($subroutine_reference,
				    @subroutine_parameters);
@output = map {chomp;$_} <$stdout_fh>;

if(equaleq(\@subroutine_parameters,\@output))
  {print("ok 3\n")}
else
  {
    $num_failed++;
    print("not ok 3\n");
  }

##
## Test 4
##

#Test a list context call to new that returns STDOUT & STDERR handles
($stdout_fh,$stderr_fh) =
  new IO::Pipe::Producer($subroutine_reference,@subroutine_parameters);
@output       = map {chomp;$_} <$stdout_fh>;
@error_output = map {chomp;$_} <$stderr_fh>;

if(equaleq(\@subroutine_parameters,\@output) &&
   equaleq(\@subroutine_parameters,\@error_output))
  {print("ok 4\n")}
else
  {
    $num_failed++;
    print("not ok 4\n");
  }

##
## Test 5
##

#Test a scalar context call to getSystemProducer
$obj = new IO::Pipe::Producer();
$stdout_fh = $obj->getSystemProducer("echo \"Hello World!\"");
@output = map {chomp;$_} <$stdout_fh>;

if("Hello World!" eq $output[0])
  {print("ok 5\n")}
else
  {
    print STDERR ("[@output] ne [Hello World!]\n");
    $num_failed++;
    print("not ok 5\n");
  }

##
## Test 6
##

#Test a list context call to getSystemProducer
$obj = new IO::Pipe::Producer();
($stdout_fh,$stderr_fh) =
  $obj->getSystemProducer("perl -e 'print \"Hello World!\";" .
			  "print STDERR join(\"\\n\",(" .
			  join(',',@subroutine_parameters) .
			  "))'");
@output       = map {chomp;$_} <$stdout_fh>;
@error_output = map {chomp;$_} <$stderr_fh>;

if("Hello World!" eq $output[0] &&
   equaleq(\@subroutine_parameters,\@error_output))
  {print("ok 6\n")}
else
  {
    print STDERR (('Hello World!' ne $output[0] ?
		   "[@output] ne [Hello World!] in STDOUT" : ''),
		  (equaleq(\@subroutine_parameters,\@error_output) ?
		   '':"[@error_output] ne [@subroutine_parameters] in STDERR"),
		  "\n");
    $num_failed++;
    print("not ok 6\n");
  }

#Exit with the number of failed tests
exit($num_failed);



#Subroutine that will be sent to the method calls in IO::Pipe::Producer
#It simply prints the parameters sent in separated by new lines
sub test
  {
    print(join("\n",@_));
    print STDERR (join("\n",@_));
  }

#The chomp'd output of the test subroutine will be tested against the list of
#arguments sent in using this subroutine which basically does a string compare
#of array elements (and a size sompare of the two arrays sent in)
sub equaleq
  {
    my $ary1 = $_[0];
    my $ary2 = $_[1];

    #If the arrays aren't the same size, issue an error and return 0 (false)
    if(scalar(@$ary1) != scalar(@$ary2))
      {
	print STDERR ("Arrays are not the same size.  The first array has ",
		      scalar(@$ary1),
		      " elements and the second array has ",
		      scalar(@$ary2),
		      " elements.\n");
	return(0);
      }

    #If any of the (assumed) scalar elements don't match, issue an error and
    #return 0 (false)
    foreach my $index (0..$#{$ary1})
      {
	if($ary1->[$index] ne $ary2->[$index])
	  {
	    print STDERR ("Elements[$index] are not the same: ",
			  "[$ary1->[$index]] ne [$ary2->[$index]].");
	    return(0);
	  }
      }

    #Return 1 (true)
    return(1);
  }

