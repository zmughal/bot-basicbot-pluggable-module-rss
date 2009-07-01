package Bot::BasicBot::Pluggable::Module::RSS;

use warnings;
use strict;
use XML::Feed;
use LWP::UserAgent;
use HTTP::Status qw(:is);

use base qw(Bot::BasicBot::Pluggable::Module);

sub init {
	my $self = shift;
	my $ua = LWP::UserAgent->new();
	$self->config({
		user_http_timeout => 10,
	});
	
	$ua->timeout($self->get('user_http_timeout'));
	$ua->env_proxy;
	
	$self->{ua} = $ua;
	$self->{feeds} = $self->get('feeds');
}

sub start {
	my ($self) = @_;
	for my $channel (keys %{$self->get('feeds')}) {
		for my $uri (keys %{$self->{feeds}->{$channel}}) {
			$self->add_feed($channel,$uri);
		}
	}
}

sub said {
	my ($self,$message) = @_;

	# Only act if we are addressed
	if ($message->{address}) {
		my $body    = $message->{body};
		my $channel = $message->{channel};

		if ($channel eq 'msg') {
			$channel = $message->{who}
		}

		my @cmds = split(' ',$body);
		if ($cmds[0] eq 'rss') {
			my %actions = (
				add    => sub { return $self->add_feed( $channel, $_[0] ) },
				list   => sub { return $self->list_feeds($channel); },
				remove => sub { return $self->remove_feed( $channel, $_[0] ) },
			);
			return $actions{$cmds[1]}->(@cmds[2,-1]);
		}
	}
}

sub add_feed {
	my ($self,$channel,$uri) = @_;
	if ($uri) {
		$self->{feeds}->{$channel}->{$uri} = 1;
		$self->set('feeds', keys %{$self->{feeds}});
		my $feed = XML::Feed->parse(URI->new($uri)) or return XML::Feed->errstr;
		for my $entry ($feed->entries()) {
			$self->{seen}->{$uri}->{$entry->title} = 1
		}
		return "Okay, added $uri."
	}
}

sub remove_feed {
	my ($self,$channel,$uri) = @_;
	if ( $self->{feeds}->{$channel}->{$uri} ) {
		delete $self->{feeds}->{$channel}->{$uri};
		$self->set('feeds', keys %{$self->{feeds}});
	} else {
		return "Mhh, i don't even know about that url";
	}
}

sub list_feeds {
	my ($self,$channel) = @_;
	my $reply;
	for my $uri (keys %{$self->{feeds}->{$channel}}) {
		$reply .= $uri . "\n";
	}
	return $reply;
}

sub reply {
	my ($self) = @_;
	for my $channel (keys %{$self->{feeds}}) {
		my $reply;
		for my $uri (keys %{$self->{feeds}->{$channel}}) {
			$self->{ua}->get($uri);
			if (is_success($response->code)){
				my $feed = XML::Feed->parse($response->content()) or warn XML::Feed->errstr;
				for my $entry ($feed->entries()) {
					if (! $self->{seen}->{$uri}->{$entry->title}++ ) {
						$reply .= $entry->title . "\n";
					}
				}
			}
		}
		if ($reply) {
			$self->tell($channel, $reply);
		}
	}
}

sub tick {
	$feeds = map { @{$self->{feeds}->{$_}} } keys %{$self->{feeds}}
	if ($self->{last_run} > time)
}

		
				

=head1 NAME

Bot::BasicBot::Pluggable::Module::RSS - The great new Bot::BasicBot::Pluggable::Module::RSS!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Bot::BasicBot::Pluggable::Module::RSS;

    my $foo = Bot::BasicBot::Pluggable::Module::RSS->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Mario Domgoergen, C<< <dom at math.uni-bonn.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bot-basicbot-pluggable-module-rss at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-RSS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::RSS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-RSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-RSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-RSS>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-RSS>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Bot::BasicBot::Pluggable::Module::RSS
