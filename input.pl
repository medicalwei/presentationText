#!/usr/bin/perl -w
use utf8;
use Net::DBus;
use Net::DBus::Reactor;
use Net::DBus::Service;
use Net::DBus::Object;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

package TextObject;

use base qw(Net::DBus::Object);
use Net::DBus::Exporter qw(org.presentationText.TextService);

sub new {
    my $class = shift;
    my $service = shift;
    my $self = $class->SUPER::new($service, "/org/presentationText/TextService/object");
				  
    
    bless $self, $class;
    
    return $self;
}

dbus_signal("newMessage", ["string"]);
dbus_method("sendNewMessage");
sub sendNewMessage {
    my $self = shift;
    print "Ready> ";
    my $msg = <STDIN>;
    return $self->emit_signal("newMessage", $msg);
}

package main;

my $bus = Net::DBus->session();
my $service = $bus->export_service("org.presentationText.TextService");
my $object = TextObject->new($service);

Net::DBus::Reactor->main->run();

