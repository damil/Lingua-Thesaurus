#!perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use Lingua::Thesaurus;

plan tests => 4;

my $db_file    = 'TEST.sqlite';
my $thesaurus = Lingua::Thesaurus->new(SQLite => $db_file);

# fulltext search with wrong accent
my @terms   = $thesaurus->search_terms('activite NOT absence');
my $n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'activite'");

# also wrong accent (on purpose)
@terms   = $thesaurus->search_terms('econôm*');
$n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'econôm'");

# parenthesis handling
@terms   = $thesaurus->search_terms('ACCORD(EXAMEN');
$n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'ACCORD(EXAMEN'");

@terms   = $thesaurus->search_terms("ACCORD(EXAMEN DES DEMANDES D'ASILE)");
$n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'ACCORD(EXAMEN DES DEMANDES D'ASILE)'");

