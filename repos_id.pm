use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v2.4)
#

package repositoryIdVisitor;

# builds $node->{repos_id}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser) = @_;
	return $self;
}

sub _set_repos_id {
	my $self = shift;
	my($node) = @_;
	unless (exists $node->{repos_id}) {
		my $version;
		if (exists $node->{version}) {
			$version = $node->{version};
		} else {
			$version = "1.0";
		}
		my $scoped_name = $node->{idf};
		$scoped_name = $node->{prefix} . "/" . $node->{idf}
				if ($node->{prefix});
		$node->{repos_id} = "IDL:" . $scoped_name . ":" . $version;
	}
}

#
#	3.5		OMG IDL Specification
#

sub visitNameSpecification {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self);
	}
}

#
#	3.6		Module Declaration
#

sub visitNameModule {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self);
	}
}

#
#	3.7		Interface Declaration
#

sub visitNameInterface {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
	foreach (@{$node->{list_decl}}) {
		if (	   $_->isa('Operation')
				or $_->isa('Attributes') ) {
			next;
		}
		$_->visitName($self);
	}
}

sub visitNameForwardInterface {
	# empty
}

#
#	3.8		Value Declaration
#

sub visitNameRegularValue {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
}

sub visitNameBoxedValue {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
}

sub visitNameAbstractValue {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
}

sub visitNameForwardRegularValue {
	# empty
}

sub visitNameForwardAbstractValue {
	# empty
}

#
#	3.9		Constant Declaration
#

sub visitNameConstant {
	# empty
}

#
#	3.10	Type Declaration
#

sub visitNameTypeDeclarators {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_value}}) {
		$_->visitName($self);
	}
}

sub visitNameTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	unless (exists $node->{modifier}) {		# native IDL2.2
		$self->_set_repos_id($node);
		$node->{type}->visitName($self);
	}
}

#
#	3.10.1	Basic Types
#

sub visitNameBasicType {
	# empty
}

#
#	3.10.2	Constructed Types
#
#	3.10.2.1	Structures
#

sub visitNameStructType {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
	foreach (@{$node->{list_expr}}) {
		if (	   $_->{type}->isa('StructType')
				or $_->{type}->isa('UnionType')
				or $_->{type}->isa('SequenceType')
				or $_->{type}->isa('FixedPtType') ) {
			$_->{type}->visitName($self);
		}
	}
}

#	3.10.2.2	Discriminated Unions
#

sub visitNameUnionType {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
	foreach (@{$node->{list_expr}}) {
		if (	   $_->{element}->{type}->isa('StructType')
				or $_->{element}->{type}->isa('UnionType')
				or $_->{element}->{type}->isa('SequenceType')
				or $_->{element}->{type}->isa('FixedPtType') ) {
			$_->{element}->{type}->visitName($self);
		}
	}
	$node->{type}->visitName($self);
}

#	3.10.2.3	Enumerations
#

sub visitNameEnumType {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
}

#
#	3.10.3	Constructed Recursive Types and Forward Declarations
#

sub visitNameForwardStructType {
	# empty
}

sub visitNameForwardUnionType {
	# empty
}

#
#	3.10.4	Template Types
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
#	3.11	Exception Declaration
#

sub visitNameException {
	my $self = shift;
	my($node) = @_;
	$self->_set_repos_id($node);
	if (exists $node->{list_expr}) {
		warn __PACKAGE__,"::visitNameException $node->{idf} : empty list_expr.\n"
				unless (@{$node->{list_expr}});
		foreach (@{$node->{list_expr}}) {
			if (	   $_->{type}->isa('StructType')
					or $_->{type}->isa('UnionType')
					or $_->{type}->isa('SequenceType')
					or $_->{type}->isa('FixedPtType') ) {
				$_->{type}->visitName($self);
			}
		}
	}
}

1;

