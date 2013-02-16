package Lingua::Thesaurus::IO::LivelinkCollectionServer;
use Moose;
with 'Lingua::Thesaurus::IO';

has '_term_rev_idx'    => (is => 'bare',
         documentation => "internal reverse index while parsing terms");

sub _reltypes {
  # default reltypes for Livelink Collection Server (formerly BasisPlus)
  return (
  #  rel    description         reverse   is_external
  #  ===    ===========         =======   ===========
    [AB  => 'Abbreviation'     => AF    => undef],
    [AF  => 'Abbreviation For' => AB    => undef],
    [EQ  => 'See Also'         => UF    => undef],
    [UF  => 'Used For'         => EQ    => undef],
    [EQA => 'See AND'          => UFA   => undef],
    [UFA => 'Used For AND'     => EQA   => undef],
    [BT  => 'Broad Term'       => NT    => undef],
    [NT  => 'Narrow Term'      => BT    => undef],
    [RT  => 'Related Term'     => RT    => undef],
    [SN  => 'Scope Note'       => undef ,  1    ],
    [HN  => 'History Note'     => undef ,  1    ],
   );
}


sub load {
  my ($self, @files) = @_;

  my $storage = $self->storage;

  # initialize storage structure
  $storage->initialize;

  # store relation types
  $storage->store_rel_type(@$_) foreach $self->_reltypes;

  # load each file
  $storage->do_transaction(sub {$self->_load_file($_)}) foreach @files;

  # cleanup internal reverse index
  $self->{_term_rev_idx} = {};

}

sub _load_file {
  my ($self, $file) = @_;

  # lecture du fichier
  open my $fh, "<", $file or die "open $file: $!";

  my %term;
  my $term_count;
  my $thesaurus_name;

 LINE:
  while (<$fh>) {
    $thesaurus_name //= do {s/^BEGIN_REL THES_NAME=(.*)//; $1}
      or next LINE;
    next LINE if /^\s*$/;
    last LINE if /^END_REL/;

  CONTINUATION_LINE:
    while (1) {
      s/\+\n$/<$fh>/e or last CONTINUATION_LINE;
    }

    my ($rel_id, $term_string) = ($_ =~ /^([A-Z]+)\d* = (.*)/)
      or die "incorrect thesaurus syntax at line $.: $_\n";

    $term_string =~ s/\s*###.*//;

    if ($rel_id eq 'LT') {
      # insert last term
      $self->_insert_term(\%term) if keys %term;

      # build a new term
      %term = (LT => $term_string);
    }
    else {
      # store relation info into current term
      push @{$term{$rel_id}}, $term_string;
    }
  }
  # insert last term
  $self->_insert_term(\%term) if keys %term;
}


sub _insert_term {
  my ($self, $term_hash) = @_;
  my $storage     = $self->storage;

  # store the lead term
  my $term_string = delete $term_hash->{LT};
  my $term_id = $self->{_term_rev_idx}{$term_string}
              //= $storage->store_term($term_string);

  # store each collection of relations
  while (my ($rel_id, $related) = each %$term_hash) {
    my $rel_type = $storage->fetch_rel_type($rel_id)
      or die "unknown relation type: $rel_id\n";

    # for internal relations, replace strings by ids of related terms
    if (!$rel_type->is_external) {
      foreach my $rel (@$related) {
        $rel = $self->{_term_rev_idx}{$rel}
             //= $storage->store_term($rel);
      }
    }

    # store it
    $storage->store_relation($term_id, $rel_id, $related);
  }
}

1;

__END__


=encoding ISO8859-1

=head1 NAME

Lingua::Thesaurus::IO::LivelinkCollectionServer - IO class for Livelink Collection Server thesaurus files

=head1 DESCRIPTION

This class implements the L<Lingua::Thesaurus::IO> role for
files issued from the I<Livelink Collection Server> database
(formerly known as I<Basis Plus>). Parsing is quite rudimentary
and does not claim to comply with the full BasisPlus specification.

=head2 File syntax

Files start with a header of shape:

  BEGIN_LAYOUT
    FORMAT=FREE
    DATA_TERM_SEPARATOR='&&&'
    END_OF_DATA_STATEMENT='@@@'
    DATA_QUAL_SEPARATOR='###'
  END_LAYOUT
  ACTION_CODE=A
  <<<
  <<<  Thesaurus dump in FREE format.
  <<<

which is completely ignored.

Actual data starts with 

  BEGIN_REL THES_NAME=<thesaurus_name>

and ends with 

  END_REL.

All data lines are of shape

  <relation_name> = <target>

If the last character on the line is '+', then this indicates that
the next line is a continuation line, which should be concatenated
to the current line.

The relation name 'LT' (for I<Lead Term>) introduces a new term.
The following lines are relations for this term, until the next LT.
Relations may be :

  #  rel    description         reverse   is_external
  #  ===    ===========         =======   ===========
    [AB  => 'Abbreviation'     => AF    => undef],
    [AF  => 'Abbreviation For' => AB    => undef],
    [EQ  => 'See Also'         => UF    => undef],
    [UF  => 'Used For'         => EQ    => undef],
    [EQA => 'See AND'          => UFA   => undef],
    [UFA => 'Used For AND'     => EQA   => undef],
    [BT  => 'Broad Term'       => NT    => undef],
    [NT  => 'Narrow Term'      => BT    => undef],
    [RT  => 'Related Term'     => RT    => undef],
    [SN  => 'Scope Note'       => undef ,  1    ],
    [HN  => 'History Note'     => undef ,  1    ],
   );

