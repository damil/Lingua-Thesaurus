package Lingua::Thesaurus::Term;
use 5.010;
use Moose;
use overload '""' => sub {$_[0]->string},
             'eq' => sub {$_[0]->string eq $_[1]};


#DO NOT use namespace::clean -except => 'meta' BECAUSE it sweeps 'overload'

has 'storage'        => (is => 'ro', does => 'Lingua::Thesaurus::Storage',
                           required => 1,
         documentation => "storage object from which this term was issued");

has 'id'               => (is => 'ro', isa => 'Str', required => 1,
         documentation => "unique storage id for the term");

has 'string'           => (is => 'ro', isa => 'Str', required => 1,
         documentation => "the term itself");


__PACKAGE__->meta->make_immutable;

sub related {
  my ($self, $rel_ids) = @_;

  return $self->storage->related($self->id, $rel_ids);
}

sub transitively_related {
  my ($self, $rel_ids, $max_depth) = @_;
  $max_depth //= 50;

  $rel_ids
    or die "missing relation type(s) for method 'transitively_related()'";
  my @results;
  my @terms   = ($self);
  my %seen    = ($self->id => 1);
  my $level = 1;
  while ($level < $max_depth && @terms) {
    my @next_related;
    foreach my $term (@terms) {
      my @step_related = $term->related($rel_ids);
      my @new_terms    = grep {!$seen{$_->[1]->id}} @step_related;
      push @next_related, map {[@$_, $term, $level]} @new_terms;
      $seen{$_->[1]->id} = 1 foreach @new_terms;
    }
    @terms = map {$_->[1]} @next_related;
    push @results, @next_related;
    $level += 1;
  }
  return @results;
}

1;

