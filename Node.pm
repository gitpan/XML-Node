# Copyright (c)  1999 Chang  Liu 
# All rights  reserved.  
#
# This program is  free software; you can redistribute  it and/or modify
# it under the same terms as Perl itself.


package XML::Node;

#use strict;
#use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

=head1 NAME

XML::Node - Node-based XML parsing: an simplified interface to XML::Parser

=head1 SYNOPSIS

 use XML::Node;

 $xml_node = new XML::Node;
 $xml_node->register( $nodetype, $callback_type => \&callback_function );
 $xml_node->register( $nodetype, $callback_type => \$variable );
    
 $xml_node->parse( $xml_filename );

=head1 DESCRIPTION

If you are only interested in processing certain nodes in an XML file, this 
module can help you simplify your Perl scripts significantly.

The XML::Node module allows you to register callback functions or variables for 
any  XML node. If you register a call back function, it will be called when
the node of the type you specified are encountered. If you register a variable, 
the content of a XML node will be appended to that variable automatically. 

Subroutine register accepts both absolute and relative node registrations.

Example of absolute path registration: 

 1. register(">TestCase>Name", "start" => \& handle_TestCase_Name_start);

Example of single node name registration:

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

Examples "test.pl" and "parse_orders.pl" come with this perl module.

=head1 BUG REPORT

Please report bugs to http://belmont-shores.ics.uci.edu/bugzilla

=head1 SEE ALSO

XML::Parser

=head1 NOTE

When you register a variable, XML::Node appends strings found to that variable. So please be sure to clear that variable when needed.

=head1 AUTHORS

Chang Liu <liu@ics.uci.edu>

=head1 LAST MODIFIED

11/04/1999

=cut


use Exporter;
$VERSION = 0.06;
@ISA = ('Exporter');
@EXPORT = qw (&register &parse);


use XML::Parser;
use Carp;


if ($ENV{DEBUG}) {
    print "DEBUG:XML::Node.pm VERSION $VERSION\n";
}

my $instance = 0;
my @selves = ();
my $myinstance;

sub new{
    my $class = shift;
    
    my $self = {
	INSTANCE       => $instance,
	START_HANDLERS => {},
	END_HANDLERS   => {},
	CHAR_HANDLERS  => {},
	CURRENT_TAG    => "",
	CURRENT_PATH   => "",
    };
    bless $self, $class;
    $selves[$instance++] = $self;
    return $self;
}

sub register
{
    $self = shift or croak "XML::Node --self is expected as THE first parameter \&register.\n";
    my $node = shift or croak "XML::Node --a node path is expected as arg1 in \&register.\n";
    my $type = shift or croak "XML::Node --node type is expected as arg2 in \&register.\n";
    my $handler = shift or croak "XML::Node --a handler is expected as arg3 in \&register.\n";
    if ($type eq "start") {
	$self->{START_HANDLERS}->{$node} = $handler;
    } elsif ($type eq "end") {
	$self->{END_HANDLERS}->{$node} = $handler;
    } elsif ($type eq "char") { 
	$self->{CHAR_HANDLERS}->{$node} = $handler;
    } else {
	croak "XML::Node --unknown handler type $type for node $node\n";
    }
}

sub parse
{
    $self = shift or croak "XML::Node --self is expected as THE first parameter \&register.\n";
    my $xml_file = shift or croak "XML::Node --an XML filename is expected in \&parse.\n";

    $myinstance = $self->{INSTANCE};
    carp "XML::Node - invoking parser [$myinstance]" if $ENV{DEBUG};

my $my_handlers = qq {
sub handle_start_$myinstance
{
    &handle_start($myinstance, \@_);
}
sub handle_end_$myinstance
{
    &handle_end($myinstance, \@_);
}
sub handle_char_$myinstance
{
    &handle_char($myinstance, \@_);
}

\$XML::Node::parser = new XML::Parser(Handlers => { Start => \\& handle_start_$myinstance,
					End =>   \\& handle_end_$myinstance,
					Char =>  \\& handle_char_$myinstance } );

};

   #carp "[[[[[[[[[[[[[[[[$my_handlers]]]]]]]]]]]]]]";
    eval ($my_handlers);
    $parser->parsefile("$xml_file");
}

sub handle_start
{
    my $myinstance = shift;
    my $p = shift;
    my $element = shift;

#    carp("handle_start called [$myinstance] [$element]\n");
    
    $selves[$myinstance]->{CURRENT_PATH} = $selves[$myinstance]->{CURRENT_PATH} . ">" .  $element;
    $selves[$myinstance]->{CURRENT_TAG} = $element;
    if ($selves[$myinstance]->{START_HANDLERS}->{$selves[$myinstance]->{CURRENT_TAG}}) {
	handle($p, $element, $selves[$myinstance]->{START_HANDLERS}->{$selves[$myinstance]->{CURRENT_TAG}});
    }
    if ($selves[$myinstance]->{START_HANDLERS}->{$selves[$myinstance]->{CURRENT_PATH}}) {
	handle($p, $element, $selves[$myinstance]->{START_HANDLERS}->{$selves[$myinstance]->{CURRENT_PATH}});
    }
}

sub handle_end
{
    my $myinstance = shift;
    my $p = shift;
    my $element = shift;

#    carp("handle_end called [$myinstance] [$element]\n");
    
    if ($selves[$myinstance]->{END_HANDLERS}->{$selves[$myinstance]->{CURRENT_TAG}}) {
	handle($p, $element, $selves[$myinstance]->{END_HANDLERS}->{$selves[$myinstance]->{CURRENT_TAG}});
    }
    if ($selves[$myinstance]->{END_HANDLERS}->{$selves[$myinstance]->{CURRENT_PATH}}) {
	handle($p, $element, $selves[$myinstance]->{END_HANDLERS}->{$selves[$myinstance]->{CURRENT_PATH}});
    }
    $selves[$myinstance]->{CURRENT_PATH} =~ /(.*)>/;
    $selves[$myinstance]->{CURRENT_PATH} = $1;
    $selves[$myinstance]->{CURRENT_TAG}  = $';
    if ($element ne $selves[$myinstance]->{CURRENT_TAG}) {
	carp "start-tag <$selves[$myinstance]->{CURRENT_TAG}> doesn't match end-tag <$element>. Is this XML file well-formed?\n";
    }
}

sub handle_char
{
    my $myinstance = shift;
    my $p = shift;
    my $element = shift;
    
#    carp("handle_char called [$myinstance] [$element]\n");

    if ($selves[$myinstance]->{CHAR_HANDLERS}->{$selves[$myinstance]->{CURRENT_TAG}}) {
	handle($p, $element, $selves[$myinstance]->{CHAR_HANDLERS}->{$selves[$myinstance]->{CURRENT_TAG}});
    }
    if ($selves[$myinstance]->{CHAR_HANDLERS}->{$selves[$myinstance]->{CURRENT_PATH}}) {
	handle($p, $element, $selves[$myinstance]->{CHAR_HANDLERS}->{$selves[$myinstance]->{CURRENT_PATH}});
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
#	chomp($element);
#	$element =~ /^(\s*)/;
#	$element = $';
#	$element =~ /(\s*)$/;
#	$element = $`;
	if (! defined $$handler) {
	    carp ("XML::Node - SCALAR handler undefined when processing [$element]");
	}
	$$handler = $$handler . $element;
    } else {
	carp "XML::Node -unknown handler type [$handler_type]\n";
	exit;
    }
}


1;
