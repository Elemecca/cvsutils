#!/usr/bin/perl -w

# enforce some good programming practices
use strict;

# Argument parsing and usage
use Getopt::Long 2.33 qw(:config posix_default bundling);
use Pod::Usage qw(pod2usage);

# CVS command interface
use Cvs ();

#
# Working copy states:
#   File status normal
# ? File exists but not in Entries
# ! File in entries but missing
# A File scheduled for addition
# D File scheduled for removal
# M File modified locally
# C Unresolved merge conflict
#
# Respository states:
#   File status normal
# ? Unversioned non-existent file
# A File added by second party
# D File removed by second party
# M File modified by second party
#
# Valid permutations:
#    File uninteresting (shown only with --show-all)
#  ? Unversioned file does not exist locally
#  A File added remotely
#  D File deleted remotely
#  M File modified remotely
# ?  Unversioned file exists locally
# ?A Remote add obstructed by unversioned local file
# A  File scheduled for addition
# AA File added locally and remotely, needs merge
# D  File scheduled for removal
# DD File deleted locally and remotely, should be fine
# DM File deleted locally and modified remotely, needs tree merge
# M  File modified locally
# MD File modified locally and deleted remotely, needs tree merge
# MM File modified locally and remotely, needs merge
# TODO: figure out the unresolved conflict system
#

#######################################################################
# Globals                                                             #
#######################################################################

# verstion number
our $VERSION = 0.1;

# whether to enable debugging output
our $debug = 0;

# whether to show uninteresting files
our $show_all = 0;

#######################################################################
# Subroutines                                                         #
#######################################################################

sub print_status_line ($) {
    my ($file) = @_;
    my $status = $file->status;
    my ($work, $repo) = (" ", " ");

    my $exists = $file->exists;
    my $rev_work = $file->working_revision;
    my $rev_repo = $file->repository_revision;

    if ($status eq "Up-to-date") {
        return unless $show_all;
    } elsif ($status eq "Unknown") {
        ($exists ? $work : $repo) = "?";
    } elsif ($status eq "Locally Modified") {
        $work = "M";
    } elsif ($status eq "Locally Added") {
        $work = "A";
    } elsif ($status eq "Locally Removed") {
        $work = "D";
    } elsif ($status eq "Needs Patch") {
        $repo = "M";
    } elsif ($status eq "Needs Checkout") {
        if (!$rev_work) {
            $work = "?" if ($exists);
            $repo = "A";
        } else {
            $work = "!" if (!$exists);
            $repo = "M" if ($rev_work ne $rev_repo);
        }
    } elsif ($status eq "Needs Merge") {
        $work = "M";
        $repo = "M";
    } elsif ($status eq "Unresolved Conflict") {
        if (!$rev_work) {
            $work = "?";
            $repo = "A";
        } else {
            $work = "C";
        }
    }

    my $line = $work . $repo . " ";
    $line .= $file->basedir . "/" if (($file->basedir or ".") ne ".");
    $line .= $file->filename;

    print $line . "\n";
}

sub callback_file ($) {
    my ($file) = @_;

    print $file->filename . ": " . $file->message . "\n" if ($file->message);

    print_status_line( $file );
}

#######################################################################
# Executable Entry Point                                              #
#######################################################################

# Parse command line arguments
Getopt::Long::GetOptions(
        'a|show-all!'   => \$show_all,
        'debug'         => \$debug,
        'manual'        => sub {
                pod2usage( -verbose => 2, -exitval => 0 );
            },	
    ) or exit 1;

# Set up the CVS library
my $cvs = new Cvs( ".", debug => $debug);
if (!$cvs) {
    print STDERR "Error initializing CVS: " . $Cvs::ERROR . "\n";
    exit 2;
}

# Get status info for everything
my $result = $cvs->status( @ARGV, { callback => \&callback_file } );
if (!$result) {
    print STDERR "Error running status command: " . $cvs->error . "\n";
    exit 2;
}

exit 0;

#######################################################################
# Documentation                                                       #
#######################################################################
=pod

=head1 NAME

cvsstat - generates a report of the status of a CVS working copy

=head1 SYNOPSIS

 cvsstat [-a] [file]...
 cvsstat <--help|--manual|--version>

=head1 DESCRIPTION

I<cvsstat> generates a report of the status of a CVS working copy, much
in the same manner as Subversion's I<svn status>.

=head1 OUTPUT FORMAT

One line is printed per file. The first two columns of the output are
each one character wide. Each summarizes one aspect of the file's
status.

=head2 First Column: working copy status

=over 4

=item ' '

no modifications

=item 'A'

The file has been scheduled for addition.

=item 'D'

The file has been scheduled for removal.

=item 'M'

The file has been locally modified.

=item 'C'

The file has an unresolved merge conflict.

=item '?'

The file is not under version control.

=item '!'

The file is under version control, but is missing.

=head1 OPTIONS

=over

=item B<-a>, B<--show-all>

Shows all files in the working copy, including uninteresting ones. By
default only files with changes are shown.

=item B<--debug>

Prints debugging information to stderr. This option generates lots
of extra information for debugging the interface with CVS. It's
probably useless except to developers and it slows down execution.

=item B<-?>, B<--help>

Prints a usage message briefly summarizing the command line options.

=item B<--manual>

Displays the full manual page (you're reading it) in your pager.

=item B<--version>

Prints the program version information.

=back

=head1 COPYRIGHT

Copyright 2011 Sam Hanes

This program is free software; see the source for copying details.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.
