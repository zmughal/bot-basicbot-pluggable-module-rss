package Bot::BasicBot::Pluggable::Module::RSS;

use warnings;
use strict;
use POE;
use POE::Component::RSSAggregator;
use Digest::MD5 qw(md5_hex);

use base qw(Bot::BasicBot::Pluggable::Module);

sub init {
    my $self = shift;
    $self->config( { feeds => {}, delay => 10, init_headlines_seen => 1 } );
    $self->{feeds} = $self->get('feeds');

    POE::Session->create(
        inline_states => {
            _start      => \&init_session,
            handle_feed => \&handle_feed,
        },
        args => [$self],
    );

}

sub init_session {
    my ( $kernel, $heap, $session, $module ) = @_[ KERNEL, HEAP, SESSION, ARG0 ];
    $heap->{rssagg} = POE::Component::RSSAggregator->new(
        alias    => 'rssagg',
        debug    => 1,
        callback => $session->postback("handle_feed"),
        tmpdir   => '/tmp',                              # optional caching
    );
    $heap->{module} = $module;
	foreach my $uri ( keys %{ $module->{feeds}} ) {
    		$kernel->post( 'rssagg', 'add_feed', $module->new_feed($uri));
	}
}

sub new_feed {
    my ( $self, $uri ) = @_;
    my $name = md5_hex($uri);	
    return {
        url                 => $uri,
        name                => $name,
        delay               => $self->get('delay'),
        init_headlines_seen => $self->get('init_headlines_seen'),
    };
}

sub handle_feed {
    my ( $kernel, $feed, $heap ) = ( $_[KERNEL], $_[ARG1]->[0], $_[HEAP] );
    my $module   = $heap->{module};
    my $uri      = $feed->url();
    my $feeds = $module->get('feeds');
    my @channels = keys %{ $feeds->{$uri} };
    for my $headline ( $feed->late_breaking_news ) {
        $module->tell( $_, $headline->headline ) for @channels;
    }
}

sub told {
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
				add    => sub { return $self->add_feed( $channel, @_ ) },
				list   => sub { return $self->list_feeds($channel); },
				remove => sub { return $self->remove_feed( $channel, @_ ) },
			);
			if (!defined($actions{$cmds[1]})) {
				return $self->help();
			}
			my $reply = $actions{$cmds[1]}->(@cmds[2,-1]) ;
			return $reply;
		}
	}
}

sub add_feed {
	my ($self,$channel,$uri) = @_;
	if ($uri and ! $self->{feeds}->{$uri}->{$channel}) {
		$self->{feeds}->{$uri}->{$channel} = 1;
		$self->set('feeds', $self->{feeds});
    		POE::Kernel->post( 'rssagg', 'add_feed', $self->new_feed($uri));
		return "Ok.";
	}
	return "Did you forget the uri or was this channel already added?";
}

sub remove_feed {
	my ($self,$channel,$uri) = @_;
	if ( $self->{feeds}->{$uri}->{$channel} ) {
		my $name = $self->{feeds}->{$uri}->{$channel};
		delete $self->{feeds}->{$uri}->{$channel};
		$self->set('feeds', keys %{$self->{feeds}});
		## We remove the feed from poco if it's the last
		if (!keys %{$self->{feeds}->{$uri}}) {
			delete $self->{feeds}->{$uri};
			my $name = md5_hex($uri);
    			POE::Kernel->post( 'rssagg', 'remove_feed', $name );
		}
		return "Ok.";
	} else {
		return "Mhh, i don't even know about that url";
	}
}

sub list_feeds {
	my ($self,$channel) = @_;
	my $reply;
	for my $uri (keys %{$self->{feeds}}) {
		if ($self->{feeds}->{$uri}->{$channel} ) {
			$reply .= "$uri\n" ;
		}
	}
	if ($reply) {
		return $reply;
	} else {
		return 'Nobody added rss feeds to me yet.';
	}
}

sub help {
	return "rss [add uri|remove|list]";
}

=head1 NAME

Bot::BasicBot::Pluggable::Module::RSS - RSS feed aggregator for your bot

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    !load RSS
    rss add http://search.cpan.org/uploads.rdf
    rss list
    rss remove http://search.cpan.org/uploads.rdf

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


=head1 SEE ALSO

L<Bot::BasicBot::Pluggable>, L<POE::Component::RSSAggregator>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Bot::BasicBot::Pluggable::Module::RSS
