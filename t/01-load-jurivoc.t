#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use Lingua::Thesaurus;

my $db_file    = 'TEST.sqlite';
my %data_files = (TF => "$FindBin::Bin/data/excerpt_jurivoc_fre.dmp",
                  GE => "$FindBin::Bin/data/palaisvoc.dmp");

unlink $db_file;
my $thesaurus = Lingua::Thesaurus->new(SQLite => $db_file);

$thesaurus->load(Jurivoc => \%data_files);

plan tests => 1;
ok (1, "$db_file loaded");
