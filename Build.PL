use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bot::BasicBot::Pluggable::Module::RSS',
    license             => 'perl',
    dist_author         => 'Mario Domgoergen <dom@math.uni-bonn.de>',
    dist_version_from   => 'lib/Bot/BasicBot/Pluggable/Module/RSS.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Bot-BasicBot-Pluggable-Module-RSS-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
