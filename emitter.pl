#!/usr/bin/perl
use utf8;
use Glib;
use Clutter;
use Net::DBus;
use Net::DBus::GLib;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

# create the dbus object

my $bus = Net::DBus::GLib->session();

my $service = $bus->get_service("org.presentationText.TextService");
my $object  = $service->get_object("/org/presentationText/TextService/object",
				   "org.presentationText.TextService");

sub message_signal_handler {
	$msg = shift;
	utf8::decode($msg);
	displayMessage($msg);
	Glib::Timeout->add( 300, sub{$object->sendNewMessage;});
}

$object->connect_to_signal("newMessage", \&message_signal_handler);

# create the main stage
Clutter::init();
$stage = Clutter::Stage->get_default();
$stage->set_color(Clutter::Color->new(0x00, 0x00, 0x00, 0xFF));
$stage->set_size(800, 600);

# add an actor and place it right in the middle
$label = Clutter::Text->new("Sans 80", "");
$label_old = Clutter::Text->new("Sans 80", "");
$label->set_color(Clutter::Color->new(0xff, 0xff, 0xff, 0xdd));
$label_old->set_color(Clutter::Color->new(0xff, 0xff, 0xff, 0xdd));
$label->set_anchor_point($label->get_width() / 2,
                         $label->get_height() / 2);
$label_old->set_anchor_point($label->get_width() / 2,
                         $label->get_height() / 2);
$label->set_position($stage->get_width() / 2, $stage->get_height() / 2);
$label_old->set_position($stage->get_width() / 2, $stage->get_height() / 2);
$stage->add($label);
$stage->add($label_old);

my $timeline = Clutter::Timeline->new(300);
my $alpha = Clutter::Alpha->new($timeline, 'ease-out-sine');
my $alpha2 = Clutter::Alpha->new($timeline, 'ease-out-sine');
my $alpha3 = Clutter::Alpha->new($timeline, 'ease-out-sine');
my $alpha_old = Clutter::Alpha->new($timeline, 'ease-out-sine');
my $alpha_old2 = Clutter::Alpha->new($timeline, 'ease-out-sine');
my $alpha_old3 = Clutter::Alpha->new($timeline, 'ease-out-sine');
my $r_behave=Clutter::Behaviour::Rotate->new($alpha, 'z-axis', 'cw', 270, 360);
my $o_behave=Clutter::Behaviour::Opacity->new($alpha2, 0, 255);
my $d_behave=Clutter::Behaviour::Depth->new($alpha3, 1000, 0);
my $r_old_behave=Clutter::Behaviour::Rotate->new($alpha_old, 'z-axis', 'cw', 0, 90);
my $o_old_behave=Clutter::Behaviour::Opacity->new($alpha_old2, 255, 0);
my $d_old_behave=Clutter::Behaviour::Depth->new($alpha_old3, 0, -1000);
$r_behave->apply($label);
$o_behave->apply($label);
$d_behave->apply($label);
$r_old_behave->apply($label_old);
$o_old_behave->apply($label_old);
$d_old_behave->apply($label_old);
$i=0;

$stage->signal_connect('show', sub{$object->sendNewMessage;});
sub displayMessage { 
	my $line=shift;
	chomp($line);
	$timeline->stop();

	$r_behave->remove_all;
	$o_behave->remove_all;
	$d_behave->remove_all;
	$r_old_behave->remove_all;
	$o_old_behave->remove_all;
	$d_old_behave->remove_all;
	if($i%2 == 1){
		$r_behave->apply($label);
		$o_behave->apply($label);
		$d_behave->apply($label);
		$r_old_behave->apply($label_old);
		$o_old_behave->apply($label_old);
		$d_old_behave->apply($label_old);
		$label->set_text($line);
		$label->set_anchor_point($label->get_width() / 2, $label->get_height() / 2);
	} else {
		$r_behave->apply($label_old);
		$o_behave->apply($label_old);
		$d_behave->apply($label_old);
		$r_old_behave->apply($label);
		$o_old_behave->apply($label);
		$d_old_behave->apply($label);
		$label_old->set_text($line);
		$label_old->set_anchor_point($label_old->get_width() / 2, $label_old->get_height() / 2);
	}
	$timeline->start();
	$i++;
};
$timeline->start();
$stage->show_all(); 

Glib::MainLoop->new()->run();
1;

