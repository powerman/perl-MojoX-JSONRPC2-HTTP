use 5.010001;
use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'Module::Build::Custom',
    code => <<'SUBCLASS' );

# Better compatibility with Gentoo ebuilds.
sub dist_version {
    my $self = shift;
    my $v = $self->SUPER::dist_version;
    $v =~ s/\Av//ms;
    return $v;
}
SUBCLASS

my $builder = $class->new(
    module_name         => 'MojoX::JSONRPC2::HTTP',
    license             => 'mit',
    dist_author         => 'Alex Efros <powerman@cpan.org>',
    dist_version_from   => 'lib/MojoX/JSONRPC2/HTTP.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build'         => 0,
    },
    requires => {
        'perl'                  => 5.010001,
        'version'               => '0.77',
        'Mojolicious'           => 0,
        'JSON::RPC2::Client'    => '0.2.0',
        'JSON::XS'              => 0,
    },
    test_requires => {
        'Test::More'            => 0,
        'Test::Exception'       => 0,
        'Test::CheckManifest'   => '0.9',
        'Test::Perl::Critic'    => 0,
        'Test::Pod'             => '1.22',
        'Test::Pod::Coverage'   => '1.08',
        'Pod::Coverage'         => '0.18',
        'Mojolicious::Plugin::JSONRPC2' => 0,
    },
#     add_to_cleanup     => [ 'MojoX-JSONRPC2-HTTP-*' ],
);

$builder->create_build_script();
