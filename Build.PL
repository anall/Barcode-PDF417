use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Barcode::PDF417',
    license             => 'artistic_2',
    dist_author         => q{Andrea Nall <anall@andreanall.com>},
    dist_version_from   => 'lib/Barcode/PDF417.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'Barcode-PDF417-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
