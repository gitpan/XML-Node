#!/usr/bin/perl -w
use XML::Node;

my $item = "";
my $quantity = "";
my $id = "";
my $date = "";

$p = XML::Node->new();

$p->register(">Orders>Order:ID","attr" => \$id);
$p->register(">Orders>Order:Date","attr" => \$date);
$p->register(">Orders>Order>Item","char" => \$item);
$p->register(">Orders>Order>Quantity","char" => \$quantity);
$p->register(">Orders>Order","end" => \&handle_order_end);

print "Processing file [orders.xml]...\n";
$p->parse("orders.xml");

sub handle_order_end
{
    print "Found order [$id] [$date] -- Item: [$item] Quantity: [$quantity]\n";
    $date = "";
    $id="";
    $item = "";
    $quantity = "";
}

