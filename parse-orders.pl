#!/usr/bin/perl -w
use XML::Node;

my $item = "";
my $quantity = "";

$p = XML::Node->new();

$p->register(">Orders>Order>Item","char" => \$item);
$p->register(">Orders>Order>Quantity","char" => \$quantity);
$p->register(">Orders>Order","end" => \&handle_order_end);

print "Processing file [orders.xml]...\n";
$p->parse("orders.xml");

sub handle_order_end
{
    print "Found order -- Item: [$item] Quantity: [$quantity]\n";
    $item = "";
    $quantity = "";
}

