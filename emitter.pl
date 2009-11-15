#!/usr/bin/perl
use utf8;
use Glib;
use Clutter;
use Net::DBus;
use Net::DBus::GLib;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

# get the dbus object

my $bus = Net::DBus::GLib->session();

my $service = $bus->get_service("org.presentationText.TextService");
my $object  = $service->get_object("/org/presentationText/TextService/object",
				   "org.presentationText.TextService");
$object->connect_to_signal("newMessage", \&message_signal_handler);

sub message_signal_handler {
	$msg = shift;
	utf8::decode($msg);
	displayMessage($msg);
	Glib::Timeout->add( 300, sub{$object->sendNewMessage;});
}

# text transition behaviours as a package
package TextBehavior;
sub newIn{
	my $class = shift;
	my $timeline = shift;
	my $rotate_alpha = Clutter::Alpha->new($timeline, 'ease-out-sine');
	my $shift_alpha = Clutter::Alpha->new($timeline, 'ease-out-sine');
	my $depth_alpha = Clutter::Alpha->new($timeline, 'ease-out-sine');
	my $self = {
		rotate_behave => Clutter::Behaviour::Rotate->new($rotate_alpha, 'z-axis', 'cw', 270, 0),
		shift_behave => Clutter::Behaviour::Opacity->new($shift_alpha, 0, 255),
		depth_behave => Clutter::Behaviour::Depth->new($depth_alpha, 1000, 0)
	};
	bless $self, $class;
	return $self;
}

sub newOut{
	my $class = shift;
	my $timeline = shift;
	my $rotate_alpha = Clutter::Alpha->new($timeline, 'ease-out-sine');
	my $shift_alpha = Clutter::Alpha->new($timeline, 'ease-out-sine');
	my $depth_alpha = Clutter::Alpha->new($timeline, 'ease-out-sine');
	my $self = {
		rotate_behave => Clutter::Behaviour::Rotate->new($rotate_alpha, 'z-axis', 'cw', 0, 90),
		shift_behave => Clutter::Behaviour::Opacity->new($shift_alpha, 255, 0),
		depth_behave => Clutter::Behaviour::Depth->new($depth_alpha, 0, -1000)
	};
	bless $self, $class;
	return $self;
}

sub apply{
	my ($self, $actor) = @_;
	$self->{rotate_behave}->apply($actor);
	$self->{shift_behave}->apply($actor);
	$self->{depth_behave}->apply($actor);
	return $actor;
}

sub remove{
	my $self = shift;
	$self->{rotate_behave}->remove_all;
	$self->{shift_behave}->remove_all;
	$self->{depth_behave}->remove_all;
	return $actor;
}

package main;

# add an actor and place it right in the middle
sub newLabel{
	$stage=shift;
	$label = Clutter::Text->new("Sans 80", "");
	$label->set_color(Clutter::Color->new(0xff, 0xff, 0xff, 0xdd));
	$label->set_anchor_point($label->get_width() / 2,
	                     $label->get_height() / 2);
	$label->set_position($stage->get_width() / 2, $stage->get_height() / 2);
	$stage->add($label);
	return $label;
}

# init clutter
Clutter::init();

# create the main stage
$stage = Clutter::Stage->get_default();
$stage->set_color(Clutter::Color->new(0x00, 0x00, 0x00, 0xFF));
$stage->set_size(800, 600);

# create 2 labels
$label_one = newLabel($stage);
$label_two = newLabel($stage);

# create a timeline and put in and out transition effects into the timeline
my $timeline = Clutter::Timeline->new(300);
my $b_in = TextBehavior->newIn($timeline);
my $b_out = TextBehavior->newOut($timeline);
$b_in->apply($label_one);
$b_out->apply($label_two);

# when the window starts to show, execute message_signal_handler to prompt input.pl for input
$stage->signal_connect('show', sub{message_signal_handler("")});

# use a globalized counter
$counter=0;

# the behaviour of display message used by message_signal_handler
sub displayMessage { 
	# receive text
	my $line=shift;
	chomp($line);

	# stop the timeline
	$timeline->stop();

	# remove behaviours
	$b_in->remove;
	$b_out->remove;
	
	# determine which one should be transition in and another one should be transition out.
	if($counter%2 == 1){
		$b_in->apply($label_one);
		$b_out->apply($label_two);
		$label_one->set_text($line);
		$label_one->set_anchor_point($label_one->get_width() / 2, $label_one->get_height() / 2);
	} else {
		$b_in->apply($label_two);
		$b_out->apply($label_one);
		$label_two->set_text($line);
		$label_two->set_anchor_point($label_two->get_width() / 2, $label_two->get_height() / 2);
	}

	# start the timeline
	$timeline->start();

	# add the counter
	$counter++;
};

# last few things
$stage->show_all(); 
Glib::MainLoop->new()->run();
1;

