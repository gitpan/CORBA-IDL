use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v3.0)
#

package repositoryIdVisitor;

# builds $node->{repos_id}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser) = @_;
	$self->{symbtab} = $parser->YYData->{symbtab};
	return $self;
}

sub _set_repos_id {
	my $self = shift;
	my($node) = @_;
	if (exists $node->{typeid}) {
		$node->{repos_id} = $node->{typeid};
	} elsif (exists $node->{id}) {
		$node->{repos_id} = $node->{id};
	} else {
		my $version;
		my $scoped_name;
		if (exists $node->{version}) {
			$version = $node->{version};
		} else {
			$version = "1.0";
		}
		if (defined $node->{_typeprefix}) {
			if ($node->{_typeprefix}) {
				$scoped_name = $node->{_typeprefix} . "/" . $node->{idf}
			} else {
				$scoped_name = $node->{idf};
			}
		} elsif ($node->{prefix}) {
			$scoped_name = $node->{prefix} . "/" . $node->{idf}
		} else {
			$scoped_name = $node->{idf};
		}
		$node->{repos_id} = "IDL:" . $scoped_name . ":" . $version;
	}
}

sub visitNameType {
	my $self = shift;
	my ($type) =@_;

	if (ref $type) {
		$type->visitName($self);
	}
}

#
#	3.5		OMG IDL Specification
#

sub visitNameSpecification {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visitName($self);
	}
}

#
#	3.6		Import Declaration
#

#
#	3.7		Module Declaration
#

sub visitNameModules {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visitName($self);
	}
}

#
#	3.8		Interface Declaration
#

sub visitNameBaseInterface {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visitName($self);
	}
}

#
#	3.9		Value Declaration
#

sub visitNameStateMember {
	# empty
}

sub visitNameInitializer {
	# empty
}

#
#	3.10		Constant Declaration
#

sub visitNameConstant {
	# empty
}

#
#	3.11	Type Declaration
#

sub visitNameTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	unless (exists $node->{modifier}) {		# native IDL2.2
		$self->_set_repos_id($node);
		$self->visitNameType($node->{type});
	}
}

#
#	3.11.1	Basic Types
#

sub visitNameBasicType {
	# empty
}

#
#	3.11.2	Constructed Types
#

sub visitNameStructType {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
	foreach (@{$node->{list_expr}}) {
		if (ref $_->{type}) {
			if (	   $_->{type}->isa('StructType')
					or $_->{type}->isa('UnionType')
					or $_->{type}->isa('SequenceType')
					or $_->{type}->isa('FixedPtType') ) {
				$_->{type}->visitName($self);
			}
		}
	}
}

sub visitNameUnionType {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
	foreach (@{$node->{list_expr}}) {
		if (ref $_->{element}->{type}) {
			if (	   $_->{element}->{type}->isa('StructType')
					or $_->{element}->{type}->isa('UnionType')
					or $_->{element}->{type}->isa('SequenceType')
					or $_->{element}->{type}->isa('FixedPtType') ) {
				$_->{element}->{type}->visitName($self);
			}
		}
	}
	$self->visitNameType($node->{type});
}

sub visitNameEnumType {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
}

#
#	3.11.3	Template Types
#

sub visitNameSequenceType {
	# empty
}

sub visitNameStringType {
	# empty
}

sub visitNameWideStringType {
	# empty
}

sub visitNameFixedPtType {
	# empty
}

#
#	3.12	Exception Declaration
#

sub visitNameException {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
	if (exists $node->{list_expr}) {
		warn __PACKAGE__,"::visitNameException $node->{idf} : empty list_expr.\n"
				unless (@{$node->{list_expr}});
		foreach (@{$node->{list_expr}}) {
			if (ref $_->{type}) {
				if (	   $_->{type}->isa('StructType')
						or $_->{type}->isa('UnionType')
						or $_->{type}->isa('SequenceType')
						or $_->{type}->isa('FixedPtType') ) {
					$_->{type}->visitName($self);
				}
			}
		}
	}
}

#
#	3.13	Operation Declaration
#

sub visitNameOperation {
	# empty
}

#
#	3.14	Attribute Declaration
#

sub visitNameAttribute {
	# empty
}

#
#	3.15	Repository Identity Related Declarations
#

sub visitTypeId {
	# empty
}

sub visitTypePrefix {
	# empty
}

#
#	3.16	Event Declaration
#

#
#	3.17	Component Declaration
#

sub visitProvides {
	# empty
}

sub visitUses {
	# empty
}

sub visitPublishes {
	# empty
}

sub visitEmits {
	# empty
}

sub visitConsumes {
	# empty
}

#
#	3.18	Home Declaration
#

sub visitFactory {
	# empty
}

sub visitFinder {
	# empty
}

1;

