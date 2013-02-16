package Lingua::Thesaurus;
use 5.010;
use Moose;
use Module::Load ();
use Carp;
use namespace::clean -except => 'meta';

our $VERSION = '0.01';

has 'storage'          => (is => 'ro', does => 'Lingua::Thesaurus::Storage',
                           handles => [qw/search_terms fetch_term/],
         documentation => "storage engine for the thesaurus");

sub BUILDARGS {
  my $class = shift;
  @_ > 1 or croak "not enough arguments";

  # load the storage subclass
  my $storage_class = $class->_load_component_class(Storage => shift);

  # instanciate storage, passing all our args, and get this as input for new()
  return {storage => $storage_class->new(@_)};
}

sub load {
  my $self     = shift;

  # load and instanciate the IO subclass
  my $io_class = $self->_load_component_class(IO => shift);
  my $io_obj   = $io_class->new(storage => $self->storage);

  # forward the call to the IO object
  $io_obj->load(@_);
}

sub _load_component_class {
  my ($class, $family, $subclass) = @_;

  # prefix $subclass by the family namespace, unless it starts with '+'
  s/^\+// or s/^/Lingua::Thesaurus::${family}::/ for $subclass;

  # load that class and return
  Module::Load::load($subclass);
  return $subclass;
}

1; # End of Lingua::Thesaurus


__END__

=head1 NAME

Lingua::Thesaurus - Thesaurus management

=head1 SYNOPSIS

=head2 Creating a thesaurus

  my $thesaurus = Lingua::Thesaurus->new(SQLite => $dbname);
  $thesaurus->load($io_class => @files);
  $thesaurus->load($io_class => {files => \@files,
                                 params  => {termClass => ..,
                                             relTypeClass => ..}});

=head2 Using a thesaurus

  my $thesaurus = Lingua::Thesaurus->new(SQLite => $dbname);

  my @terms = $thesaurus->search_terms('*foo*');
  my $term  = $thesaurus->fetch_term('foobar');

  foreach my $pair ($term->related(qw/NT RT/)) {
    my ($rel_type, $item) = @$pair;
    say "  $rel_type = $item";
  }

=head1 DESCRIPTION

This distribution manages I<thesauri>. A thesaurus is a list of
terms, with some relations between them (like for example "broader term" /
"narrower term").

Thesauri are loaded from one or several I<IO formats>; usually this will be
the ISO 2788 format, or some derivative from it. See classes under the 
L<Lingua::Thesaurus::IO> namespace for various implementations.
At the moment, IO classes only implement loading; dumping methods
will be added in a future version.

Once loaded, thesauri are stored via a I<storage class>; this is
meant to be an efficient internal structure for performing searches.
Currently, only L<Lingua::Thesaurus::Storage::SQLite> is implemented;
but the architecture allows for other storage classes to be defined,
as long as they comply with the L<Lingua::Thesaurus::Storage> role.

Terms are retrieved through the L</"search_terms"> and L</"fetch_term">
methods. The results are instances of L<Lingua::Thesaurus::Term>;
these objects have navigation methods for retrieving related terms.

This distribution was originally targeted for dealing with the
Swiss thesaurus for justice "Jurivoc"
(see L<Lingua::Thesaurus::IO::Jurivoc>).
However, the framework should be easily extensible to other needs.
Other Perl modules for thesauri are briefly discussed below
in the L</"SEE ALSO"> section.

Side note: another motivation for writing this distribution was also
to experiment with L<Moose> meta-programming possibilities.
Subclasses of L<Lingua::Thesaurus::Term> are created dynamically
for implementing relation methods C<NT>, C<BT>, etc. ---
see L<Lingua::Thesaurus::Storage::SQLite> source code.

=head1 METHODS

=head2 new

  my $thesaurus = Lingua::Thesaurus->new($storage_class => @storage_args);

Instanciates a thesaurus on a given storage.
The C<$storage_class> will be automatically prefixed by
C<Lingua::Thesaurus::Storage>, unless the classname contains
an initial C<'+'>. The remaining arguments are transmitted to the
storage class. Since L<Lingua::Thesaurus::Storage::SQLite> is the default
storage class supplied with this distribution, thesauri are usually opened
as 

  my $dbname = '/path/to/some/file.sqlite';
  my $thesaurus = Lingua::Thesaurus->new(SQLite => $dbname);

=head2 load

  $thesaurus->load($io_class => @files);
  $thesaurus->load($io_class => {files => \@files,
                                 params  => {termClass    => ..,
                                             relTypeClass => ..}});

Populates a thesaurus database with data from thesauri dumpfiles.  The
job of parsing these files is delegated to some C<IO> subclass, given
as first argument. The C<$io_class> will be automatically prefixed by
C<Lingua::Thesaurus::IO>, unless the classname contains an initial
C<'+'>. The remaining arguments are transmitted to the IO class; the
simplest form is just a list of dumpfiles. See IO subclasses
in the L<Lingua::Thesaurus::IO> namespace for more details.

=head3 search_terms

  my @terms = $thesaurus->search_terms($pattern);

Searches the term database according to C<$pattern>, where
the pattern may contain C<'*'> to mean word completion.

The interpretation of patterns depends on the storage
engine; by default, this is implemented using SQLite's
"LIKE" function (see
and L<http://www.sqlite.org/doc/lang_expr.html#like>).
Characters C<'*'> in the pattern are translated into
C<'%'> for the LIKE function to work as expected.

It is also possible to configure the storage to use fulltext
searches, so that pattern C<'sci*'> would also match
C<'computer science'>; see
L<Lingua::Thesaurus::Storage::SQLite/use_fulltext>.

If C<$pattern> is empty, the method returns the list
of all terms in the thesaurus.

Results are instances of L<Lingua::Thesaurus::Term>.

=head3 fetch_term

  my $term = $thesaurus->fetch_term($term_string);

Retrieves a specific term;
Returns an instance of L<Lingua::Thesaurus::Term>
(or C<undef> if the term is unknown).


=head1 SEE ALSO

  - Thesaurus : just synonyms

  - Biblio::Thesaurus : stored in memory
    Biblio::Thesaurus::SQLite : not really related to Biblio::Thesaurus
     (no inheritance)

  - Text::Thesaurus::ISO  : 1998, dbmopen, limited relations


=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-thesaurus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Thesaurus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Thesaurus


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Thesaurus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-Thesaurus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-Thesaurus>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-Thesaurus/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>


=cut


