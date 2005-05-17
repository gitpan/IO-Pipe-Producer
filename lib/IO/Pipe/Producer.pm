## Producer.pm
##
## Author:  Robert W. Leach
## Date:    3/7/2003
## Company: Los Alamos National Laboratory

package IO::Pipe::Producer;
use base qw(IO::Pipe);
use Carp;

$Producer::VERSION = '1.5';

#NOTICE
#
#This software and ancillary information (herein called "SOFTWARE") called
#Producer.pm is made available under the terms described here.  The
#SOFTWARE has been approved for release with associated LA-CC number
#LA-CC-05-060.
#
#Unless otherwise indicated, this software has been authored by an employee or
#employees of the University of California, operator of the Los Alamos National
#Laboratory under Contract No. W-7405-ENG-36 with the U.S. Department of
#Energy.  The U.S. government has rights to use, reproduce, and distribute this
#SOFTWARE.  The public may copy, distribute, prepare derivative works and
#publicly display this SOFTWARE without charge, provided that this notice and
#any statement of authorship are reproduced on all copies.  Neither the
#government nor the university makes any warranty, express or implied, or
#assumes any liability or responsibility for the use of this SOFTWARE.
#
#If SOFTWARE is modified to produce derivative works, such modified SOFTWARE
#should be clearly marked, so as not to confuse it with the version available
#from LANL.



#Constructor

sub new
  {
    #Get the class name
    my $class = shift(@_);
    #Instantiate an instance of the super class
    my $self = $class->SUPER::new();
    #Bless the instantiation into this class so we can call our own methods
    bless($self,$class);
    #If a subroutine call was supplied
    if(scalar(@_))
      {
	#Declare file handles for STDOUT and STDERR
	my($fh,$eh);
	#If new was called in list context
	if(wantarray)
	  {
	    #Fill the handles with the outputs from the subroutine
	    ($fh,$eh) = $self->getSubroutineProducer(@_);
	    #Return blessed referents to the file handles
	    return(bless($fh,$class),bless($eh,$class));
	  }
	#Fill the STDOUT handle with the output from the subroutine
	$fh = $self->getSubroutineProducer(@_);
	#Return blessed referent to the STDOUT handle
	return(bless($fh,$class));
      }
    #Return a blessed referent of the object hash
    if(wantarray)
      {return($self,bless($class->SUPER::new(),$class))}
    return($self);
  }



#This method is also a constructor
sub getSubroutineProducer
  {
    #Read in subroutine reference
    my $self         = shift;
    my $producer_sub = shift;
    my @params       = @_;
    my($pid,$error);

    if(!defined($producer_sub) || ref($producer_sub) ne 'CODE')
      {
	$error = "ERROR:Producer.pm:getSubroutineProducer:A referenced " .
	  "subroutine is required as the first argument to " .
	    "getSubroutineProducer.\n";
	$Producer::errstr = $error;
	carp($error);
	return(undef);
      }

    #Create a pipe
    my $stdout_pipe = $self->SUPER::new();
    my $stderr_pipe = $self->SUPER::new();

    #Fork off the Producer
    if(defined($pid = fork()))
      {
	if($pid)
	  {
	    ##
	    ## Parent
	    ##

	    #Create a read file handle
	    $stdout_pipe->reader();
	    $stderr_pipe->reader();
	    #Return the read file handle to the consumer
	    if(wantarray)
	      {return(bless($stdout_pipe,ref($self)),
		      bless($stderr_pipe,ref($self)))}
	    return(bless($stdout_pipe,ref($self)));
	  }
	else
	  {
	    ##
	    ## Child
	    ##

	    #Create a write file handle for the Producer
	    $stdout_pipe->writer();
	    $stdout_pipe->autoflush;
	    $stderr_pipe->writer();
	    $stderr_pipe->autoflush;

	    #Redirect standard outputs to the pipes or kill the child
	    if(!open(STDOUT,">&",\${$stdout_pipe}))
	      {
		$error = "ERROR:Producer.pm:getSubroutineProducer:Can't " .
		  "redirect stdout to pipe: [" .
		    select($stdout_pipe) .
		      "]. $!";
		$Producer::errstr = $error;
		croak($error);
	      }
	    elsif(!open(STDERR,">&",\${$stderr_pipe}))
	      {
		$error = "ERROR:Producer.pm:getSubroutineProducer:Can't " .
		  "redirect stderr to pipe: [" .
		    select($stderr_pipe) .
		      "]. $!";
		$Producer::errstr = $error;
		croak($error);
	      }

	    #Call the subroutine passed in (ignore it's return value)
	    $producer_sub->(@params);

	    #Close the pipes (hence it's unnecessary to do so in the consumer)
	    $stdout_pipe->close();
	    $stderr_pipe->close();

	    #Successfully exiting the child process
	    exit(0);
	  }
      }
    else
      {
	$error = "ERROR:Producer.pm:getSubroutineProducer:fork() didn't " .
	  "work!\n";
	$Producer::errstr = $error;
	carp($error);
	return(undef);
      }
  }


sub getSystemProducer
  {
    my $self = shift;
    return($self->getSubroutineProducer(sub {system(@_)},@_));
  }



=head1 NAME

IO::Pipe::Producer

=head1 AUTHOR

IO::Pipe::Producer was written by Robert W. Leach I<E<lt>robleach@lanl.govE<gt>> in 2005.

=head1 SYNOPSIS
 
 # Module which provides 2 methods: getSubroutineProducer
 # and getSystemProducer.  They take a subroutine reference
 # (with associated arguments) and a system call
 # respectively and return (blessed) handles on their
 # streaming standard output and standard error output.
 
 
 # EXAMPLES of usage
 
 use IO::Pipe::Producer;
 $obj = new IO::Pipe::Producer();
 $stdout_fh =
   $obj->getSubroutineProducer($subroutine_reference,
                               @subroutine_parameters);
 
 # OR
 
 use IO::Pipe::Producer;
 $obj = new IO::Pipe::Producer();
 ($stdout_fh,$stderr_fh) =
   $obj->getSubroutineProducer($subroutine_reference,
                               @subroutine_parameters);
 
 # OR
 
 use IO::Pipe::Producer;
 $stdout_fh = new IO::Pipe::Producer($subroutine_reference,
 				    @subroutine_parameters);
 
 # OR
 
 use IO::Pipe::Producer;
 ($stdout_fh,$stderr_fh) =
   new IO::Pipe::Producer($subroutine_reference,
                          @subroutine_parameters);
 
 # Then you can read the returned handles like any other
 # file handle...
 
 while(<$stdout_fh>)
   {print "STDOUT From Producer: $_"}
 while(<$stderr_fh>)
   {print "STDERR From Producer: $_"}
 
 # You can also do the same thing with system calls using
 # the getSystemProducer subroutine.  However, this feature
 # is not accessible via the new constructor
 
 use IO::Pipe::Producer;
 $obj = new IO::Pipe::Producer();
 $stdout_fh =
   $obj->getSystemProducer("echo \"Hello World!\"");
 
 use IO::Pipe::Producer;
 $obj = new IO::Pipe::Producer();
 ($stdout_fh,$stderr_fh) =
   $obj->getSystemProducer("echo \"Hello World!\"");
 
 # However, this is exactly the same as:
 
 use IO::Pipe::Producer;
 $stdout_fh = new Producer(sub{system(@_)},
			   "echo \"Hello World!\"");
 
 # OR
 
 use IO::Pipe::Producer;
 ($stdout_fh,$stderr_fh) =
   new IO::Pipe::Producer(sub{system(@_)},
			  "echo \"Hello World!\"");
 
=head1 ABSTRACT

Producer.pm is useful for piggy-backing large data processing subroutines or system calls.  Instead of making each call serially and waiting for a return or playing with temporary files, you can create a Producer that will continuosly generate output that can be further processed right away in your script.  One benefit is immediate feedback.  It's basically a way to pipe the standard output of a forked subroutine or system call to a file handle in your parent process.

=head1 DESCRIPTION

Producer.pm is a module that provides methods to fork off a subroutine or system call and return handles on the standard output (STDOUT and STDERR).  If you have (for example) a subroutine that processes a very large text file and performs a task on each line, but you need to perform further processing with either other subroutines or in main, normally you would have to wait until the subroutine returns to get its output (either by returning it or opening a temporary file that it produced) and continue processing.  If the subroutine prints its output to STDOUT (and STDERR) or you can edit it to do so, you can call it using a Producer so that you can use the returned handle to continuously process each line as it's "produced".  You can chain subroutines together like this by having your subroutine itself create a Producer.  This is similar to using open() to run a system call, except that with this module, you can get a handle on STDERR and use it with subroutines as well.

=head1 NOTES

This module was originally written as a simple subrotuine in a library that simply used IO::Pipe.  I decided to make it into a subclass of IO::Pipe even though it only really adds one method and a helper method (Note: The getSystemProducer method calls getSubroutineProducer) because libraries seem antiquated to me.  I'm open to better design suggestions however.  I also decided to bless the returns of all the methods because they were retuning IO::Pipe objects anyway.  The basic trick this module uses can be gleaned from the IO::Pipe documentation if you read between the lines and combine various tidbits from different sections, but to simplify it, it simply "opens" the file handle inside the IO::Pipe data structure to accept output from the output file handles (STDOUT/STDERR) as input, which is the basic definition of a pipe.

=head1 NOTICE

This software and ancillary information (herein called "SOFTWARE") called Producer.pm is made available under the terms described here.  The SOFTWARE has been approved for release with associated LA-CC number LA-CC-05-060.

Unless otherwise indicated, this software has been authored by an employee or employees of the University of California, operator of the Los Alamos National Laboratory under Contract No. W-7405-ENG-36 with the U.S. Department of Energy.  The U.S. government has rights to use, reproduce, and distribute this SOFTWARE.  The public may copy, distribute, prepare derivative works and publicly display this SOFTWARE without charge, provided that this notice and any statement of authorship are reproduced on all copies.  Neither the government nor the university makes any warranty, express or implied, or assumes any liability or responsibility for the use of this SOFTWARE.

If SOFTWARE is modified to produce derivative works, such modified SOFTWARE should be clearly marked, so as not to confuse it with the version available from LANL.

=head1 BUGS

No known bugs.  Please report them to I<E<lt>robleach@lanl.govE<gt>> if you find any.

=head1 SEE ALSO

L<IO::Pipe>

=cut



1;
