package XML::Node;

#use strict;
#use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

=head1 NAME

XML::Node::register - register a call back function or a variable for a particular node

XML::Node::parse - parse an XML file

=head1 SYNOPSIS

    use XML::Node;

    register( $nodetype, $callback_type => \&callback_function );
    register( $nodetype, $callback_type => \$variable );
    
    parse( $xml_filename );

=head1 DESCRIPTION

If you are only interested in processing certain nodes in an XML file, this 
module can help you.

The XML::Node module allows you to register callback functions or variables for 
any  XML node. If you register a call back function, it will be called when
the node of the type you specified are encountered. If you register a variable, 
the content of a XML node will be appended to that variable automatically. 

Subroutine &register accepts both absolute and relative node registrations.

Example of absolute path registration: 

 1. register(">TestCase>Name", "start" => \& handle_TestCase_Name_start);

Example of single node registration:

 2. register( "Name", "start" => \& handle_Name_start);
 3. register( "Name", "end"   => \& handle_Name_end);
 4. register( "Name", "char"  => \& handle_Name_char);

Abosolute path trigger condition is recommended because a "Name" tage could appear in different
places and stands for differe name. 

Example:

  1  <Testcase>
  2     <Name>Something</Name>
  3     <Oracle>
  4         <Name>Something</Name>
  5     </Oracle>
  6  </Testcase>

Statement 1 causes &handle_TestCase_Name_start to be called when parsing Line 2. Statements 2,3,4 cause the three handler subroutines to be called when parsing both Line 2 and Line 4.

This module uses XML::Parser.

=head1 EXAMPLE

File "test.pl", which comes with this perl module, has an example.

=head1 NOTE

When you register a variable, XML::Node appends strings found to that variable. So please be sure to clear that variable when needed.

=head1 AUTHORS

Chang Liu <liu@ics.uci.edu>

=head1 LAST MODIFIED

10/20/1999

=cut


use Exporter;
$VERSION = 0.04;
@ISA = ('Exporter');
@EXPORT = qw (&register &parse);


use XML::Parser;


if ($ENV{DEBUG}) {
    print "DEBUG:XML::Node.pm VERSION $VERSION\n";
}

my %start_handlers = ();
my %end_handlers   = ();
my %char_handlers  = ();
my $current_tag = "";    # for example, "Name"
my $current_path = "";   # for example, ">TestSuite>TestCase>Name";

sub register
{
    my $node = shift or die "XML::Node --a node path is expected as arg1 in \&register.\n";
    my $type = shift or die "XML::Node --node type is expected as arg2 in \&register.\n";
    my $handler = shift or die "XML::Node --a handler is expected as arg3 in \&register.\n";
    if ($type eq "start") {
	$start_handlers{$node} = $handler;
    } elsif ($type eq "end") {
	$end_handlers{$node} = $handler;
    } elsif ($type eq "char") { 
	$char_handlers{$node} = $handler;
    } else {
	die "XML::Node --unknown handler type $type for node $node\n";
    }
}

sub parse
{
    my $xml_file = shift or die "XML::Node --an XML filename is expected in \&parse.\n";

    my $p2 = new XML::Parser(Handlers => { Start => \& handle_start,
					   End =>   \& handle_end,
					   Char =>  \& handle_char } );
    $p2->parsefile("$xml_file");
}


sub handle_start
{
    my $p = shift;
    my $element = shift;
    
    $current_path = $current_path . ">" .  $element;
    $current_tag = $element;
    if ($start_handlers{$current_tag}) {
#      debug("calling start handler of $current_tag");
	handle($p, $element, $start_handlers{$current_tag});
    }
    if ($start_handlers{$current_path}) {
#      debug("calling start handler of $current_path");
	handle($p, $element, $start_handlers{$current_path});
    }
}

sub handle_end
{
    my $p = shift;
    my $element = shift;
    
#  debug ("end of $element, current_path: [$current_path] current_tag: [$current_tag]");
    if ($end_handlers{$current_tag}) {
#      debug("calling end handler of $current_tag");
	handle($p, $element, $end_handlers{$current_tag});
    }
    if ($end_handlers{$current_path}) {
#      debug("calling end handler of $current_path");
	handle($p, $element, $end_handlers{$current_path});
    }
    $current_path =~ /(.*)>/;
    $current_path = $1;
    $current_tag = $';
    if ($element ne $current_tag) {
	print "XML::Node --ERROR:start-tag <$current_tag> doesn't match end-tag <$element>. Is this XML file well-formed?\n";
    }
}

sub handle_char
{
    my $p = shift;
    my $element = shift;
    
    if ($char_handlers{$current_tag}) {
#      debug("calling char handler $char_handlers{$current_tag} of $current_tag");
	handle($p, $element, $char_handlers{$current_tag});
    }
    if ($char_handlers{$current_path}) {
#      debug("calling char handler $char_handlers{$current_path} of $current_path");
	handle($p, $element, $char_handlers{$current_path});
    }
}

sub handle
{
    my $p = shift;
    my $element = shift;
    my $handler = shift;

    my $handler_type = ref($handler);
    if ($handler_type eq "CODE") {
	&$handler($p,$element);
    } elsif ($handler_type eq "SCALAR")  {
	chomp($element);
	$element =~ /^(\s*)/;
	$element = $';
	$element =~ /(\s*)$/;
	$element = $`;
	$$handler = $$handler . $element;
    } else {
	print "XML::Node --unknown handler type [$handler_type]\n";
	exit;
    }
}


1;
