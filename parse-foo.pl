#!/usr/bin/perl -w
use XML::Node;

$p = XML::Node->new();

$p->register( "foo", 'char' => \$variable );

my $file = "foo.xml";

print "Processing file [$file]...\n";

open(FOO, $file);
$p->parse(*FOO);
close(FOO);

print "Variable : [$variable]\n";

