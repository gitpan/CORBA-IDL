use strict;
use UNIVERSAL;

package asciiVisitor;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser) = @_;
	$self->{srcname} = $parser->YYData->{srcname};
	$self->{seq} = [];					# recursion prevention
	my $filename = $self->{srcname};
	$filename =~ s/^([^\/]+\/)+//;
	$filename =~ s/\.idl$//i;
	$filename .= '.ast';
	open(STDOUT, "> $filename")
			or die "can't open $filename ($!).\n";
	return $self;
}

sub reset_tab {
	my $self = shift;
	$self->{tab} = '';
}

sub inc_tab {
	my $self = shift;
	$self->{tab} .= "\t";
}

sub dec_tab {
	my $self = shift;
	$self->{tab} =~ s/\t$//;
}

sub get_tab {
	my $self = shift;
	return $self->{tab};
}

#
#	3.5		OMG IDL Specification
#

sub visitSpecification {
	my $self = shift;
	my($node) = @_;
	$self->reset_tab();
	print "source $self->{srcname} \n\n";
	foreach (@{$node->{list_decl}}) {
		$_->visit($self);
	}
}

#
#	3.6		Module Declaration
#

sub visitModule {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "module $node->{idf} '$node->{repos_id}'\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	foreach (@{$node->{list_decl}}) {
		$_->visit($self);
	}
	$self->dec_tab();
}

#
#	3.7		Interface Declaration
#

sub visitInterface {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "interface $node->{idf} '$node->{repos_id}'\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	my $found = 0;						# recursion prevention
	foreach (@{$self->{seq}}) {
		if ($_ == $node) {
			$found = 1;
			last;
		}
	}
	if ($found) {
		print $self->get_tab(), "recursion \n";
	} else {
		push @{$self->{seq}}, $node;
		if (exists $node->{modifier}) {		# abstract or local
			print $self->get_tab(), "modifier $node->{modifier}\n";
		}
		if (exists $node->{list_inheritance}) {
			foreach (@{$node->{list_inheritance}}) {
				print $self->get_tab(), "inheritance $_->{idf}\n";
			}
		}
		foreach (@{$node->{list_decl}}) {
			$_->visit($self);
		}
		pop @{$self->{seq}};
	}
	$self->dec_tab();
}

sub visitForwardInterface {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "forward interface $node->{idf}\n";
	$self->inc_tab();
	if (exists $node->{modifier}) {		# abstract or local
		print $self->get_tab(), "modifier $node->{modifier}\n";
	}
	$self->dec_tab();
}

#
#	3.8		Value Declaration
#
#	3.8.1	Regular Value Type
#

sub visitRegularValue {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "regular value $node->{idf} '$node->{repos_id}'\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	my $found = 0;						# recursion prevention
	foreach (@{$self->{seq}}) {
		if ($_ == $node) {
			$found = 1;
			last;
		}
	}
	if ($found) {
		print $self->get_tab(), "recursion \n";
	} else {
		push @{$self->{seq}}, $node;
		if (exists $node->{modifier}) {		# custom
			print $self->get_tab(), "modifier $node->{modifier}\n";
		}
		if (exists $node->{inheritance}) {
			$node->{inheritance}->visit($self);
		}
		foreach (@{$node->{list_decl}}) {
			$_->visit($self);
		}
		pop @{$self->{seq}};
	}
	$self->dec_tab();
}

sub visitInheritanceSpec {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "inheritance spec\n";
	$self->inc_tab();
	if (exists $node->{modifier}) {		# truncatable
		print $self->get_tab(), "modifier $node->{modifier}\n";
	}
	if (exists $node->{list_value}) {
		foreach (@{$node->{list_value}}) {
			print $self->get_tab(), "value $_->{idf}\n";
		}
	}
	if (exists $node->{list_interface}) {
		foreach (@{$node->{list_interface}}) {
			print $self->get_tab(), "interface $_->{idf}\n";
		}
	}
	$self->dec_tab();
}

sub visitStateMembers {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "state members\n";
	$self->inc_tab();
	foreach (@{$node->{list_value}}) {
		$_->visit($self);
	}
	$self->dec_tab();
}

sub visitStateMember {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "$node->{modifier} $node->{idf}";
	$self->inc_tab();
	$node->{type}->visit($self);
	foreach (@{$node->{array_size}}) {
		$_->visit($self);				# expression
	}
	$self->dec_tab();
}

sub visitFactory {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "factory $node->{idf}\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	foreach (@{$node->{list_param}}) {
		$_->visit($self);
	}
	$self->dec_tab();
}

#
#	3.8.2	Boxed Value Type
#

sub visitBoxedValue {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "boxed value $node->{idf} '$node->{repos_id}'\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	$node->{type}->visit($self);
	$self->dec_tab();
}

#
#	3.8.3	Abstract Value Type
#

sub visitAbstractValue {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "abstract value $node->{idf} '$node->{repos_id}'\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	if (exists $node->{inheritance}) {
		$node->{inheritance}->visit($self);
	}
	$self->dec_tab();
}

#
#	3.8.4	Value Forward Declaration
#

sub visitForwardRegularValue {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "forward regular value $node->{idf}\n";
}

sub visitForwardAbstractValue {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "forward abstract value $node->{idf}\n";
}

#
#	3.9		Constant Declaration
#

sub visitConstant {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "constant $node->{idf}\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	$node->{type}->visit($self);
	$node->{value}->visit($self);		# expression
	$self->dec_tab();
}

sub visitExpression {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "expression value $node->{value}\n";
	$self->inc_tab();
	foreach (@{$node->{list_expr}}) {
		if ($_->isa('Constant')) {
			print $self->get_tab(), "constant $_->{idf}\n";
		} else {
			$_->visit($self);			# literal, unop, binop
		}
	}
	$self->dec_tab();
}

sub visitUnaryOp {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "unop $node->{op}\n";
}

sub visitBinaryOp {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "binop $node->{op}\n";
}

sub visitLiteral {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "literal $node->{value}\n";
}

#
#	3.10	Type Declaration
#

sub visitTypeDeclarators {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "type declarators\n";
	$self->inc_tab();
	foreach (@{$node->{list_value}}) {
		$_->visit($self);
	}
	$self->dec_tab();
}

sub visitTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	if (exists $node->{modifier}) {		# native IDL2.2
		print $self->get_tab(), "type declarator $node->{idf}\n";
		$self->inc_tab();
		print $self->get_tab(), "modifier $node->{modifier}\n";
	} else {
		print $self->get_tab(), "type declarator $node->{idf} '$node->{repos_id}'\n";
		$self->inc_tab();
		print $self->get_tab(), "doc: $node->{doc}\n"
				if (exists $node->{doc});
		$node->{type}->visit($self);
		if (exists $node->{array_size}) {
			foreach (@{$node->{array_size}}) {
				$_->visit($self);				# expression
			}
		}
	}
	$self->dec_tab();
}

#
#	3.10.1	Basic Types
#

sub visitBasicType {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "basic type $node->{value}\n";
}

#
#	3.10.2	Constructed Types
#
#	3.10.2.1	Structures
#

sub visitStructType {
	my $self = shift;
	my($node) = @_;
	if (defined $node->{list_expr}) {
		print $self->get_tab(), "struct $node->{idf} '$node->{repos_id}'\n";
		$self->inc_tab();
		push @{$self->{seq}}, $node;
		foreach (@{$node->{list_expr}}) {
			$_->visit($self);				# members
		}
#		foreach (@{$node->{list_value}}) {
#			$_->visit($self);				# single or array
#		}
		pop @{$self->{seq}};
		$self->dec_tab();
	} else {
		print $self->get_tab(), "struct $node->{idf} (forward)\n";
	}
}

sub visitMembers {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "members\n";
	$self->inc_tab();
	foreach (@{$node->{list_value}}) {
		$_->visit($self);				# single or array
	}
	$self->dec_tab();
}

sub visitArray {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "array $node->{idf}\n";
	$self->inc_tab();
	$node->{type}->visit($self);
	foreach (@{$node->{array_size}}) {
		$_->visit($self);				# expression
	}
	$self->dec_tab();
}

sub visitSingle {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "single $node->{idf}\n";
	$self->inc_tab();
	$node->{type}->visit($self);
	$self->dec_tab();
}

#	3.10.2.2	Discriminated Unions
#

sub visitUnionType {
	my $self = shift;
	my($node) = @_;
	if (defined $node->{list_expr}) {
		print $self->get_tab(), "union $node->{idf} '$node->{repos_id}'\n";
		$self->inc_tab();
		print $self->get_tab(), "doc: $node->{doc}\n"
				if (exists $node->{doc});
		push @{$self->{seq}}, $node;
		foreach (@{$node->{list_expr}}) {
			$_->visit($self);				# case
		}
		pop @{$self->{seq}};
		$self->dec_tab();
	} else {
		print $self->get_tab(), "union $node->{idf} (forward)\n";
	}
}

sub visitCase {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "case\n";
	$self->inc_tab();
	foreach (@{$node->{list_label}}) {
		$_->visit($self);				# default or expression
	}
	$node->{element}->visit($self);
	$self->dec_tab();
}

sub visitDefault {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "default\n";
}

sub visitElement {
	my $self = shift;
	my($node) = @_;
	$node->{value}->visit($self);		# array or single
}

#	3.10.2.3	Enumerations
#

sub visitEnumType {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "enum $node->{idf} '$node->{repos_id}'\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	foreach (@{$node->{list_expr}}) {
		$_->visit($self);				# enum
	}
	$self->dec_tab();
}

sub visitEnum {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "$node->{idf}\n";
}

#
#	3.10.3	Constructed Recursive Types and Forward Declarations
#

sub visitForwardStructType {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "forward struct $node->{idf}\n";
}

sub visitForwardUnionType {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "forward union $node->{idf}\n";
}

#
#	3.10.4	Template Types
#

sub visitSequenceType {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "sequence\n";
	$self->inc_tab();
	my $found = 0;						# recursion prevention
	foreach (@{$self->{seq}}) {
		if ($_ eq $node->{type}) {
			$found = 1;
			last;
		}
	}
	if ($found) {
		print $self->get_tab(), "recursion $node->{type}->{idf}\n";
	} else {
		push @{$self->{seq}}, $node;
		$node->{type}->visit($self);
		pop @{$self->{seq}};
	}
	if (exists $node->{max}) {
		$node->{max}->visit($self);
	}
	$self->dec_tab();
}

sub visitStringType {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "string\n";
	$self->inc_tab();
	if (exists $node->{max}) {
		$node->{max}->visit($self);
	}
	$self->dec_tab();
}

sub visitWideStringType {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "wstring\n";
	$self->inc_tab();
	if (exists $node->{max}) {
		$node->{max}->visit($self);
	}
	$self->dec_tab();
}

sub visitFixedPtType {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "fixed\n";
	$self->inc_tab();
	if (exists $node->{d}) {
		$node->{d}->visit($self);
		$node->{s}->visit($self);
	}
	$self->dec_tab();
}

#
#	3.11	Exception Declaration
#

sub visitException {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "exception $node->{idf} '$node->{repos_id}'\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	if (exists $node->{list_expr}) {
		foreach (@{$node->{list_expr}}) {
			$_->visit($self);			# members
		}
	}
#	foreach (@{$node->{list_value}}) {
#		$_->visit($self);				# single or array
#	}
	$self->dec_tab();
}

#
#	3.12	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "operation $node->{idf}\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	if (exists $node->{attr}) {			# oneway
		print $self->get_tab(), "attribute $node->{attr}\n";
	}
	$node->{type}->visit($self);
	foreach (@{$node->{list_param}}) {
		$_->visit($self);				# parameter
	}
	if (exists $node->{list_raise}) {
		foreach (@{$node->{list_raise}}) {		# exception
			print $self->get_tab(), "raise $_->{idf}\n";
		}
	}
	if (exists $node->{list_context}) {
		foreach (@{$node->{list_context}}) {	# string literal
			print $self->get_tab(), "context $_->{value}\n";
		}
	}
	$self->dec_tab();
}

sub visitParameter {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "parameter $node->{idf}\n";
	$self->inc_tab();
	# in, out, inout
	print $self->get_tab(), "attribute $node->{attr}\n";
	$node->{type}->visit($self);
	$self->dec_tab();
}

sub visitVoidType {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "void\n";
}

#
#	3.13	Attribute Declaration
#

sub visitAttributes {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "attributes\n";
	$self->inc_tab();
	foreach (@{$node->{list_value}}) {
		$_->visit($self);				# attribute
	}
	$self->dec_tab();
}

sub visitAttribute {
	my $self = shift;
	my($node) = @_;
	print $self->get_tab(), "attribute $node->{idf}\n";
	$self->inc_tab();
	print $self->get_tab(), "doc: $node->{doc}\n"
			if (exists $node->{doc});
	if (exists $node->{modifier}) {		# readonly
		print $self->get_tab(), "modifier $node->{modifier}\n";
	}
	$node->{type}->visit($self);
	$self->dec_tab();
}

1;

