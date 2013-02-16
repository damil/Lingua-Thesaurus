package Lingua::Thesaurus::Storage;
use Moose::Role;
use Moose::Meta::Class;
use namespace::clean -except => 'meta';

has 'params'           => (is => 'ro', isa => 'HashRef',
                           lazy => 1, builder => '_params',
                           predicate => 'has_params',
         documentation => "params saved in storage");

has 'term_class'       => (is => 'ro', isa => 'ClassName',
                           lazy => 1, builder => '_build_term_class',
                           init_arg => undef,
         documentation => "dynamic class for terms");

has 'relType_class'    => (is => 'ro', isa => 'ClassName',
                           lazy => 1, builder => '_relType_class',
                           init_arg => undef,
         documentation => "class for relTypes");

requires 'search_terms';
requires 'fetch_term';
requires 'related';
requires 'fetch_rel_type';
requires 'rel_types';

requires 'do_transaction';
requires 'initialize';
requires 'store_rel_type';
requires 'store_relation';
requires 'store_term';
requires 'finalize';

requires '_params';

sub _build_term_class {
  my ($self) = @_;

  # compute subclass name from the list of possible relations
  my @rel_ids       = $self->rel_types;
  my $subclass_name = join "_", "auto", sort @rel_ids;
  my $parent_class  = $self->_parent_term_class;
  my $pkg_name      = "${parent_class}::${subclass_name}";

  # build a closure for each relation type (NT, BT, etc.)
  my %methods;
  foreach my $rel_id (@rel_ids) {
    $methods{$rel_id} = sub {my $self = shift;
                             my @rel  = map {$_->[1]} $self->related($rel_id);
                             return wantarray ? @rel : $rel[0];};
  }

  # dynamically create a new subclass
  my $subclass = Moose::Meta::Class->create(
    $pkg_name,
    superclasses => [$parent_class],
    methods      => \%methods,
   );

  return $pkg_name;
}


#======================================================================
# utilities
#======================================================================

sub _parent_term_class {
  my $self = shift;
  my $parent_term_class =  $self->params->{term_class}
                       || 'Lingua::Thesaurus::Term';
  Module::Load::load $parent_term_class;
  return $parent_term_class;
}


sub _relType_class {
  my $self = shift;
  my $relType_class =  $self->params->{relType_class} 
                    || 'Lingua::Thesaurus::RelType';
  Module::Load::load $relType_class;
  return $relType_class;
}



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

