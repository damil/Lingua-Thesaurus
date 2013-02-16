package Lingua::Thesaurus::Storage;
use Moose::Role;
use namespace::clean -except => 'meta';

requires 'search_terms';
requires 'fetch_term';
requires 'related';
requires 'fetch_rel_type';

requires 'do_transaction';
requires 'initialize';
requires 'store_rel_type';
requires 'store_relation';
requires 'store_term';
requires 'finalize';

1;

__END__

=head1 NAME

Lingua::Thesaurus::Storage - Role for thesaurus storage

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 Retrieval methods

=head3 search_terms

=head3 fetch_term

=head3 related

=head3 fetch_rel_type


=head2 Populating the database

=head3 initialize

=head3 do_transaction

=head3 store_term

=head3 store_rel_type

=head3 store_relation

=head3 finalize

