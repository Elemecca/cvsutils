use Module::Build 0.37;
my $build = Module::Build->new(
        dist_name       => "CVS-Utils",
        dist_author     => "Sam Hanes <sam@maltera.com>",
        dist_abstract   => "utilities to simplify life with CVS",
        dist_version    => 0.1,
        license         => "GPL_3",
        release_status  => "unstable",
    );
$build->create_build_script;
