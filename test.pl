#!/usr/bin/perl -w
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}


use XML::Node;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
# The following sample script calculates how many test cases there are in 
#   a test suite XML file.
#
# The XML file name can be passed as a parameter. Example:
#   perl test.pl test.xml
#

my $suite_name = "";
my $testcase_name = "";
my $xml_filename = "test.xml";
my $testcase_no = 0;
my $arg1 = shift;

if ($arg1) {
    $xml_filename = $arg1;
}

$p = XML::Node->new();

$p->register(">TestSuite>SuiteName","char" => \$ suite_name);
$p->register(">TestSuite>TestCase>Name","char" => \$testcase_name);
$p->register(">TestSuite>TestCase","end" => \& handle_testcase_end);
$p->register(">TestSuite","end" => \& handle_testsuite_end);

print "\nProcessing file [$xml_filename]...\n";
$p->parse($xml_filename);

print "ok 2\n";

sub handle_testcase_end
{
    print "Found test case [$testcase_name]\n";
    $testcase_name = "";
    $testcase_no ++;
}

sub handle_testsuite_end
{
    print "\n--There are $testcase_no test cases in test suite [$suite_name]\n\n";
    $testcase_name = "";
}




