use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v2.4)
#

package node;
use vars qw($VERSION);
$VERSION = '1.01';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %attr = @_;
	my $self = \%attr;
	bless($self, $class);
	foreach (keys %attr) {
		unless (defined $self->{$_}) {
			delete $self->{$_};
		}
	}
	return $self;
}

sub configure {
	my $self = shift;
	my %attr = @_;
	my ($key,$value);
	while ( ($key,$value) = each(%attr) ) {
		if (defined $value) {
			$self->{$key} = $value;
		}
	}
	return $self;
}

sub line_stamp {
	my $self = shift;
	my ($parser) = @_;
	$self->{filename} = $parser->YYData->{filename};
	$self->{lineno} = $parser->YYData->{lineno};
}

sub visit {
	# overloaded in : BasicType, Literal
	my $self = shift;
	my $class = ref $self;
	my $visitor = shift;
	my $func = 'visit' . $class;
	$visitor->$func($self,@_);
}

sub visitName {
	# overloaded in : BasicType
	my $self = shift;
	my $class = ref $self;
	my $visitor = shift;
	my $func = 'visitName' . $class;
	return $visitor->$func($self,@_);
}

package Dummy;

@Dummy::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new node(node => @_);
	bless($self, $class);
	return $self;
}

#
#	3.5		OMG IDL Specification
#

package Specification;

@Specification::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

#
#	3.6		Module Declaration
#

package Module;

@Module::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->OpenModule($self->{idf},$self);
	$parser->YYData->{symbtab}->PushCurrentRoot($self);
	$parser->YYData->{symbtab}->Insert($self->{idf},new Dummy($self));
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

#
#	3.7		Interface Declaration
#

package Interface;

@Interface::ISA = qw(node);

sub _CheckInheritance {
	my $self = shift;
	my($parser) = @_;
	$self->{hash_attribute_operation} = {};
	if (exists $self->{list_inheritance}) {
		# 3.7.5	Interface Inheritance
		my %hash;
		foreach (@{$self->{list_inheritance}}) {
			my $name = $_->{idf};
			if (exists $hash{$name}) {
				$parser->Warning("'$name' redeclares inheritance.\n");
			} else {
				$hash{$name} = $_;
			}
		}
		$self->configure(hash_inheritance => \%hash);
		if (exists $self->{modifier} and $self->{modifier} eq 'abstract') {
			foreach (@{$self->{list_inheritance}}) {
				if (! exists $_->{modifier} or $_->{modifier} ne 'abstract') {
					$parser->Error("'$_->{idf}' is not abstract.\n");
				}
			}
		}
		# 3.7.6 Local Interface
		foreach (@{$self->{list_inheritance}}) {
			if (exists $_->{modifier} and $_->{modifier} eq 'local') {
				if (! exists $self->{modifier} or $_->{modifier} ne 'local') {
					$parser->Error("'$self->{idf}' is not local.\n");
				}
				last;
			}
		}
		foreach (@{$self->{list_inheritance}}) {
			my $base = $_;
			foreach (keys %{$base->{hash_attribute_operation}}) {
				if (exists $self->{hash_attribute_operation}{$_}) {
					if ($self->{hash_attribute_operation}{$_} != $base->{hash_attribute_operation}{$_}) {
						$parser->Error("multi inheritance of '$_'.\n");
					}
				} else {
					my $node = $base->{hash_attribute_operation}{$_};
					$self->{hash_attribute_operation}{$_} = $node;
					$parser->YYData->{symbtab}->Insert($_,$node);
				}
			}
		}
	}
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{symbtab}->Insert($self->{idf},new Dummy($self));
	$parser->YYData->{curr_itf} = $self;
	$self->line_stamp($parser);
	$self->_CheckInheritance($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

sub Lookup {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser,$name) = @_;
	my $node = $parser->YYData->{symbtab}->Lookup($name);
	if (defined $node) {
	 	if ($node->isa('ForwardInterface')) {
			$parser->Error("'$name' is declared, but not defined.\n");
	 	} elsif (! $node->isa($class)) {
			$parser->Error("'$name' is not a $class.\n");
		}
	}
	return $node;
}

package ForwardInterface;

@ForwardInterface::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->InsertForward($self->{idf},$self);
	$self->line_stamp($parser);
	return $self;
}

#
#	3.8		Value Declaration
#
#	3.8.1	Regular Value Type
#

package RegularValue;

@RegularValue::ISA = qw(node);

sub _CheckInheritance {
	my $self = shift;
	my($parser) = @_;
	if (exists $self->{inheritance}
			and exists $self->{inheritance}->{modifier}		# truncatable
			and exists $self->{modifier} ) {				# custom
		$parser->Error("'truncatable' is used in a custom value.\n");
	}
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{symbtab}->Insert($self->{idf},new Dummy($self));
	$parser->YYData->{curr_itf} = $self;
	$self->line_stamp($parser);
	$self->_CheckInheritance($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

sub Lookup {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser,$name) = @_;
	my $node = $parser->YYData->{symbtab}->Lookup($name);
	if (defined $node) {
	 	if (	    $node->isa('ForwardRegularValue')
	 			and $node->isa('ForwardAbstractValue') ) {
			$parser->Error("'$name' is declared, but not defined.\n");
	 	} elsif (   ! $node->isa($class)
	 			and ! $node->isa('BoxedValue')
	 			and ! $node->isa('AbstractValue') ) {
			$parser->Error("'$name' is not a value.\n");
		}
	}
	return $node;
}

#
#	3.8.1.3	Value Inheritance Specification
#

package InheritanceSpec;

@InheritanceSpec::ISA = qw(node);

sub _CheckInheritance {
	my $self = shift;
	my($parser) = @_;
	# 3.8.5	Valuetype Inheritance
	if (exists $self->{list_name}) {
		my %hash;
		foreach (@{$self->{list_name}}) {
			my $name = $_->{idf};
			if (exists $hash{$name}) {
				$parser->Warning("'$name' redeclares inheritance.\n");
			} else {
				$hash{$name} = $_;
			}
		}
	}
	if (exists $self->{list_interface}) {
		my %hash;
		foreach (@{$self->{list_interface}}) {
			my $name = $_->{idf};
			if (exists $hash{$name}) {
				$parser->Warning("'$name' redeclares inheritance.\n");
			} else {
				$hash{$name} = $_;
			}
		}
	}
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->_CheckInheritance($parser);
	return $self;
}

#
#	3.8.1.4	State Members
#

package StateMembers;

@StateMembers::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	my @list;
	foreach (@{$self->{list_expr}}) {
		my $member;
		my @array_size = @{$_};
		my $idf = shift @array_size;
		if (@array_size) {
#			$member = new Array($parser,
			$member = new StateMember($parser,
					modifier		=>	$self->{modifier},
					type			=>	$self->{type},
					idf				=>	$idf,
					array_size		=>	\@array_size
			);
			if ($parser->YYData->{IDL_version} ge '2.4') {
				$parser->Deprecated("Anonymous type (array).\n");
			}
		} else {
#			$member = new Single($parser,
			$member = new StateMember($parser,
					modifier		=>	$self->{modifier},
					type			=>	$self->{type},
					idf				=>	$idf,
			);
		}
		push @list, $member;
	}
	$self->configure(list_value	=>	\@list);
	TypeDeclarator->CheckDeprecated($parser,$self->{type});
	TypeDeclarator->CheckForward($parser,$self->{type});
	return $self;
}

package StateMember;					# modifier, idf, type[, array_size]

@StateMember::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

#
#	3.8.1.5	Initializers
#

package Factory;

@Factory::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$parser->YYData->{unnamed_symbtab} = new UnnamedSymbtab($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my @list_in = ();
	my @list_inout = ();
	my @list_out = ();
	foreach ( @{$self->{list_param}} ) {
		if      ($_->{attr} eq 'in') {
			unshift @list_in, $_;
		} elsif ($_->{attr} eq 'inout') {
			unshift @list_inout, $_;
		} elsif ($_->{attr} eq 'out') {
			unshift @list_out, $_;
		}
	}
	$self->{list_in} = \@list_in;
	$self->{list_inout} = \@list_inout;
	$self->{list_out} = \@list_out;
	return $self;
}

#
#	3.8.2	Boxed Value Type
#
package BoxedValue;

@BoxedValue::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

#
#	3.8.3	Abstract Value Type
#

package AbstractValue;

@AbstractValue::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{symbtab}->Insert($self->{idf},new Dummy($self));
	$parser->YYData->{curr_itf} = $self;
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

#
#	3.8.4	Value Forward Declaration
#

package ForwardRegularValue;

@ForwardRegularValue::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->InsertForward($self->{idf},$self);
	$self->line_stamp($parser);
	return $self;
}

package ForwardAbstractValue;

@ForwardAbstractValue::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->InsertForward($self->{idf},$self);
	$self->line_stamp($parser);
	return $self;
}

#
#	3.9		Constant Declaration
#

package Expression;
use Math::BigInt;
use Math::BigFloat;

use constant UCHAR_MAX		=> new Math::BigInt(                       '255');
use constant SHRT_MIN		=> new Math::BigInt(                   '-32 768');
use constant SHRT_MAX		=> new Math::BigInt(                    '32 767');
use constant USHRT_MAX		=> new Math::BigInt(                    '65 535');
use constant LONG_MIN		=> new Math::BigInt(            '-2 147 483 648');
use constant LONG_MAX		=> new Math::BigInt(             '2 147 483 647');
use constant ULONG_MAX		=> new Math::BigInt(             '4 294 967 295');
use constant LLONG_MIN		=> new Math::BigInt('-9 223 372 036 854 775 808');
use constant LLONG_MAX		=> new Math::BigInt( '9 223 372 036 854 775 807');
use constant ULLONG_MAX		=> new Math::BigInt('18 446 744 073 709 551 615');
use constant FLT_MAX  		=> new Math::BigFloat(         '3.40282347e+38' );
use constant DBL_MAX  		=> new Math::BigFloat('1.79769313486231571e+308');
use constant LDBL_MAX 		=> new Math::BigFloat('1.79769313486231571e+308');
use constant FLT_MIN  		=> new Math::BigFloat(         '1.17549435e-38' );
use constant DBL_MIN  		=> new Math::BigFloat('2.22507385850720138e-308');
use constant LDBL_MIN 		=> new Math::BigFloat('2.22507385850720138e-308');

@Expression::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	if (        ! exists $self->{type} ) {
		$self->configure(
				type	=>	new IntegerType($parser,
									value	=>	'unsigned long',
									auto	=>	1
							)
		);
	} elsif (   @{$self->{list_expr}} == 1
			and defined $self->{list_expr}[0] ) {
		my $expr = $self->{list_expr}[0];
		if (	    $self->{type}->isa('WideCharType')
				and $expr->isa('CharacterLiteral') ) {
			$self->{list_expr} = [
					new WideCharacterLiteral($parser,
							value	=>	$expr->{value}
					)
			];
		} elsif (   $self->{type}->isa('WideStringType')
				and $expr->isa('StringLiteral') ) {
			$self->{list_expr} = [
					new WideStringLiteral($parser,
							value	=>	$expr->{value}
					)
			];
		}
	}
	$self->configure(
			value	=>	$self->Eval($parser)
	);
	return $self;
}

sub Eval {
	my $self = shift;
	my($parser) = @_;
	my @list_expr = @{$self->{list_expr}};		# create a copy
	return _Eval($parser,$self->{type},\@list_expr);
}

sub _EvalBinop {
	my($parser,$type,$elt,$list_expr) = @_;
	if (	   $type->isa('IntegerType')
			or $type->isa('OctetType') ) {
		my $right = _Eval($parser,$type,$list_expr);
		return undef unless (defined $right);
		my $left = _Eval($parser,$type,$list_expr);
		return undef unless (defined $left);
		if (	  $elt->{op} eq '|' ) {
			my $value = $left->bior($right);
			return _CheckRange($parser,$type,new Math::BigInt($value));
		} elsif ( $elt->{op} eq '^' ) {
			my $value = $left->bxor($right);
			return _CheckRange($parser,$type,new Math::BigInt($value));
		} elsif ( $elt->{op} eq '&' ) {
			my $value = $left->band($right);
			return _CheckRange($parser,$type,new Math::BigInt($value));
		} elsif ( $elt->{op} eq '+' ) {
			my $value = $left->badd($right);
			return _CheckRange($parser,$type,new Math::BigInt($value));
		} elsif ( $elt->{op} eq '-' ) {
			my $value = $left->bsub($right);
			return _CheckRange($parser,$type,new Math::BigInt($value));
		} elsif ( $elt->{op} eq '*' ) {
			my $value = $left->bmul($right);
			return _CheckRange($parser,$type,new Math::BigInt($value));
		} elsif ( $elt->{op} eq '/' ) {
			my ($value) = $left->bdiv($right);
			return _CheckRange($parser,$type,new Math::BigInt($value));
		} elsif ( $elt->{op} eq '%' ) {
			my $value = $left->bmod($right);
			return _CheckRange($parser,$type,new Math::BigInt($value));
		} elsif ( $elt->{op} eq '>>' ) {
			if (0 <= $right and $right < 64) {
				my $value = $left->brsft($right);
				return _CheckRange($parser,$type,new Math::BigInt($value));
			} else {
				$parser->Error("shift operation out of range.\n");
				return undef;
			}
		} elsif ( $elt->{op} eq '<<' ) {
			if (0 <= $right and $right < 64) {
				my $value = $left->blsft($right);
				return _CheckRange($parser,$type,new Math::BigInt($value));
			} else {
				$parser->Error("shift operation out of range.\n");
				return undef;
			}
		} else {
			$parser->Error("_BinopEval (int) : INTERNAL ERROR.\n");
			return undef;
		}
	} elsif (  $type->isa('FloatingPtType') ) {
		my $right = _Eval($parser,$type,$list_expr);
		return undef unless (defined $right);
		my $left = _Eval($parser,$type,$list_expr);
		return undef unless (defined $left);
		if (      $elt->{op} eq '+' ) {
			my $value = $left->fadd($right);
			return _CheckRange($parser,$type,new Math::BigFloat($value));
		} elsif ( $elt->{op} eq '-' ) {
			my $value = $left->fsub($right);
			return _CheckRange($parser,$type,new Math::BigFloat($value));
		} elsif ( $elt->{op} eq '*' ) {
			my $value = $left->fmul($right);
			return _CheckRange($parser,$type,new Math::BigFloat($value));
		} elsif ( $elt->{op} eq '/' ) {
			my $value = $left->fdiv($right);
			return _CheckRange($parser,$type,new Math::BigFloat($value));
		} elsif (  $elt->{op} eq '|'
				or $elt->{op} eq '^'
				or $elt->{op} eq '&'
				or $elt->{op} eq '>>'
				or $elt->{op} eq '<<'
				or $elt->{op} eq '%' ) {
			$parser->Error("'$elt->{op}' is not valid for '$type'.\n");
		} else {
			$parser->Error("_EvalBinop (fp) : INTERNAL ERROR.\n");
			return undef;
		}
	} elsif (  $type->isa('FixedPtType') ) {
		my $right = _Eval($parser,$type,$list_expr);
		return undef unless (defined $right);
		my $left = _Eval($parser,$type,$list_expr);
		return undef unless (defined $left);
		if (      $elt->{op} eq '+' ) {
			my $value = $left->fadd($right);
			return _CheckRange($parser,$type,new Math::BigFloat($value));
		} elsif ( $elt->{op} eq '-' ) {
			my $value = $left->fsub($right);
			return _CheckRange($parser,$type,new Math::BigFloat($value));
		} elsif ( $elt->{op} eq '*' ) {
			my $value = $left->fmul($right);
			return _CheckRange($parser,$type,new Math::BigFloat($value));
		} elsif ( $elt->{op} eq '/' ) {
			my $value = $left->fdiv($right);
			return _CheckRange($parser,$type,new Math::BigFloat($value));
		} elsif (  $elt->{op} eq '|'
				or $elt->{op} eq '^'
				or $elt->{op} eq '&'
				or $elt->{op} eq '>>'
				or $elt->{op} eq '<<'
				or $elt->{op} eq '%' ) {
			$parser->Error("'$elt->{op}' is not valid for '$type'.\n");
			return undef;
		} else {
			$parser->Error("_EvalBinop (fixed) : INTERNAL ERROR.\n");
			return undef;
		}
	} else {
		$parser->Error("'$type->{value}' can't use expression.\n");
		return undef;
	}
}

sub _EvalUnop {
	my($parser,$type,$elt,$list_expr) = @_;
	if (	   $type->isa('IntegerType')
			or $type->isa('OctetType') ) {
		my $right = _Eval($parser,$type,$list_expr);
		return undef unless (defined $right);
		if (	  $elt->{op} eq '+' ) {
			return _CheckRange($parser,$type,$right);
		} elsif ( $elt->{op} eq '-' ) {
			my $value = $right->bneg();
			return _CheckRange($parser,$type,new Math::BigInt($value));
		} elsif ( $elt->{op} eq '~' ) {
			my $value;
			if      ($type->{value} eq 'unsigned short') {
				$value = USHORT_MAX->bsub($right);
			} elsif ($type->{value} eq 'unsigned long') {
				$value = ULONG_MAX->bsub($right);
			} elsif ($type->{value} eq 'unsigned long long') {
				$value = ULLONG_MAX->bsub($right);
			} elsif ($type->{value} eq 'octet') {
				$value = UCHAR_MAX->bsub($right);
			} else {	# signed
				$value = $right->badd(1)->bneg();
			}
			return _CheckRange($parser,$type,new Math::BigInt($value));
		} else {
			$parser->Error("_EvalUnop (int) : INTERNAL ERROR.\n");
			return undef;
		}
	} elsif (  $type->isa('FloatingPtType') ) {
		my $right = _Eval($parser,$type,$list_expr);
		return undef unless (defined $right);
		if (	  $elt->{op} eq '+' ) {
			return _CheckRange($parser,$type,$right);
		} elsif ( $elt->{op} eq '-' ) {
			my $value = $right->fneg();
			return _CheckRange($parser,$type,new Math::BigFloat($value));
		} elsif (  $elt->{op} eq '~' ) {
			$parser->Error("'$elt->{op}' is not valid for '$type'.\n");
			return undef;
		} else {
			$parser->Error("_EvalUnop (fp) : INTERNAL ERROR.\n");
			return undef;
		}
	} elsif (  $type->isa('FixedPtType') ) {
		my $right = _Eval($parser,$type,$list_expr);
		return undef unless (defined $right);
		if (	  $elt->{op} eq '+' ) {
			return _CheckRange($parser,$type,$right);
		} elsif ( $elt->{op} eq '-' ) {
			my $value = $right->fneg();
			return _CheckRange($parser,$type,new Math::BigFloat($value));
		} elsif (  $elt->{op} eq '~' ) {
			$parser->Error("'$elt->{op}' is not valid for '$type'.\n");
			return undef;
		} else {
			$parser->Error("_EvalUnop (fixed) : INTERNAL ERROR.\n");
			return undef;
		}
	} else {
		$parser->Error("'$type->{value}' can't use expression.\n");
		return undef;
	}
}

sub _Eval {
	my($parser,$type,$list_expr) = @_;
	my $elt = pop @$list_expr;
	if (! defined $elt) {
		return undef;
	} elsif ($elt->isa('BinaryOp'))	{
		return _EvalBinop($parser,$type,$elt,$list_expr);
	} elsif ($elt->isa('UnaryOp')) {
		return _EvalUnop($parser,$type,$elt,$list_expr);
	} elsif ($elt->isa('Constant')) {
		if (ref $type eq ref $elt->{value}->{type}) {
			return _CheckRange($parser,$type,$elt->{value}->{value});
		} else {
			$parser->Error("'$elt->{value}->{value}' is not a '$type->{value}'.\n");
			return undef;
		}
	} elsif ($elt->isa('Enum')) {
		if ($type eq $elt->{type}) {
			return $elt;
		} else {
			$parser->Error("'$elt->{idf}' is not a '$type->{idf}'.\n");
			return undef;
		}
	} elsif ($elt->isa('IntegerLiteral')) {
		if ($type->isa('IntegerType')) {
			return _CheckRange($parser,$type,$elt->{value});
		} elsif ($type->isa('OctetType')) {
			return _CheckRange($parser,$type,$elt->{value});
		} else {
			$parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
			return undef;
		}
	} elsif ($elt->isa('StringLiteral')) {
		if ($type->isa('StringType')) {
			return _CheckRange($parser,$type,$elt->{value});
		} else {
			$parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
			return undef;
		}
	} elsif ($elt->isa('WideStringLiteral')) {
		if ($type->isa('WideStringType')) {
			return _CheckRange($parser,$type,$elt->{value});
		} else {
			$parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
			return undef;
		}
	} elsif ($elt->isa('CharacterLiteral')) {
		if ($type->isa('CharType')) {
			return $elt->{value};
		} else {
			$parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
			return undef;
		}
	} elsif ($elt->isa('WideCharacterLiteral')) {
		if ($type->isa('WideCharType')) {
			return $elt->{value};
		} else {
			$parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
			return undef;
		}
	} elsif ($elt->isa('FixedPtLiteral')) {
		if ($type->isa('FixedPtType')) {
			return _CheckRange($parser,$type,$elt->{value});
		} else {
			$parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
			return undef;
		}
	} elsif ($elt->isa('FloatingPtLiteral')) {
		if ($type->isa('FloatingPtType')) {
			return _CheckRange($parser,$type,$elt->{value});
		} else {
			$parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
			return undef;
		}
	} elsif ($elt->isa('BooleanLiteral')) {
		if ($type->isa('BooleanType')) {
			return $elt->{value};
		} else {
			$parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
			return undef;
		}
	} else {
		$parser->Error("_Eval: INTERNAL ERROR ",ref $elt," .\n");
		return undef;
	}
}

sub _CheckRange {
	my($parser,$type,$value) = @_;
	if (       $type->isa('IntegerType') ) {
		if (     $type->{value} eq 'short' ) {
			if ($value >= SHRT_MIN and $value <= SHRT_MAX) {
				return $value;
			} else {
				$parser->Error("'$type->{value}' $value is out of range.\n");
				return undef;
			}
		} elsif ($type->{value} eq 'long') {
			if ($value >= LONG_MIN and $value <= LONG_MAX) {
				return $value;
			} else {
				$parser->Error("'$type->{value}' $value is out of range.\n");
				return undef;
			}
		} elsif ($type->{value} eq 'long long') {
			if ($value >= LLONG_MIN and $value <= LLONG_MAX) {
				return $value;
			} else {
				$parser->Error("'$type->{value}' $value is out of range.\n");
				return undef;
			}
		} elsif ($type->{value} eq 'unsigned short') {
			if ($value >= 0 and $value <= USHRT_MAX) {
				return $value;
			} else {
				$parser->Error("'$type->{value}' $value is out of range.\n");
				return undef;
			}
		} elsif ($type->{value} eq 'unsigned long') {
			if ($value >= 0 and $value <= ULONG_MAX) {
				return $value;
			} else {
				$parser->Error("'$type->{value}' $value is out of range.\n");
				return undef;
			}
		} elsif ($type->{value} eq 'unsigned long long') {
			if ($value >= 0 and $value <= ULLONG_MAX) {
				return $value;
			} else {
				$parser->Error("'$type->{value}' $value is out of range.\n");
				return undef;
			}
		} else {
			$parser->Error("_CheckRange IntegerType : INTERNAL ERROR.\n");
			return undef;
		}
	} elsif (  $type->isa('OctetType') ) {
		if ($value >= 0 and $value <= UCHAR_MAX) {
			return $value;
		} else {
			$parser->Error("'$type->{value}' $value is out of range.\n");
			return undef;
		}
	} elsif (  $type->isa('FloatingPtType') ) {
		my $abs_v = abs $value;
		if (     $type->{value} eq 'float' ) {
			if ($abs_v >= FLT_MIN and $abs_v <= FLT_MAX) {
				return $value;
			} else {
				$parser->Error("'$type->{value}' $value is out of range.\n");
				return undef;
			}
		} elsif ($type->{value} eq 'double') {
			if ($abs_v >= DBL_MIN and $abs_v <= DBL_MAX) {
				return $value;
			} else {
				$parser->Error("'$type->{value}' $value is out of range.\n");
				return undef;
			}
		} elsif ($type->{value} eq 'long double') {
			if ($abs_v >= LDBL_MIN and $abs_v <= LDBL_MAX) {
				return $value;
			} else {
				$parser->Error("'$type->{value}' $value is out of range.\n");
				return undef;
			}
		} else {
			$parser->Error("_CheckRange FloatingPtType : INTERNAL ERROR.\n");
			return undef;
		}
	} elsif (  $type->isa('FixedPtType') ) {
		return $value;
	} elsif (  $type->isa('StringType')
			or $type->isa('WideStringType') ) {
		if (exists $type->{max}) {
			my @lst = split //,$value;
			my $len = @lst;
			if ($len <= $type->{max}->{value}) {
				return $value;
			} else {
				$parser->Error("'$type->{value}' '$value' is out of range.\n");
				return undef;
			}
		}
		return $value;
	}
}

package Constant;

@Constant::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->line_stamp($parser);
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	my $type = $self->{type};
	TypeDeclarator->CheckDeprecated($parser,$type);
	while ($type->isa('TypeDeclarator')) {
		$type = $type->{type};
		if (		! $type->isa('IntegerType')
				and ! $type->isa('CharType')
				and ! $type->isa('WideCharType')
				and ! $type->isa('BooleanType')
				and ! $type->isa('FloatingPtType')
				and ! $type->isa('StringType')
				and ! $type->isa('WideStringType')
				and ! $type->isa('OctetType')
				and ! $type->isa('EnumType') ) {
			$parser->Error("'$self->{type}->{idf}' refers a bad type for constant.\n");
			return $self;
		}
	}
	$self->configure(
			value	=>	new Expression($parser,
								type		=>	$type,
								list_expr	=>	$self->{list_expr}
						)
	);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

sub Lookup {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser,$name) = @_;
	my $node = $parser->YYData->{symbtab}->Lookup($name);
	if (defined $node) {
	 	if (		! $node->isa($class)
	 			and ! $node->isa('Enum') ) {
			$parser->Error("'$name' is not a $class.\n");
		}
	}
	return $node;
}

package UnaryOp;

@UnaryOp::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

package BinaryOp;

@BinaryOp::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

#
#	3.2.5	Literals
#

package Literal;

@Literal::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

sub visit {
	my $self = shift;
	my($visitor) = @_;
	$visitor->visitLiteral($self);
}

package IntegerLiteral;

@IntegerLiteral::ISA = qw(Literal);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new Literal(@_);
	bless($self, $class);
	return $self;
}

package StringLiteral;

@StringLiteral::ISA = qw(Literal);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new Literal(@_);
	bless($self, $class);
	return $self;
}

package WideStringLiteral;

@WideStringLiteral::ISA = qw(Literal);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new Literal(@_);
	bless($self, $class);
	return $self;
}

package CharacterLiteral;

@CharacterLiteral::ISA = qw(Literal);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new Literal(@_);
	bless($self, $class);
	return $self;
}

package WideCharacterLiteral;

@WideCharacterLiteral::ISA = qw(Literal);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new Literal(@_);
	bless($self, $class);
	return $self;
}

package FixedPtLiteral;

@FixedPtLiteral::ISA = qw(Literal);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new Literal(@_);
	bless($self, $class);
	return $self;
}

package FloatingPtLiteral;

@FloatingPtLiteral::ISA = qw(Literal);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new Literal(@_);
	bless($self, $class);
	return $self;
}

package BooleanLiteral;

@BooleanLiteral::ISA = qw(Literal);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new Literal(@_);
	bless($self, $class);
	return $self;
}

#
#	3.10	Type Declaration
#

package TypeDeclarator;

@TypeDeclarator::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

sub Lookup {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser,$name) = @_;
	my $node = $parser->YYData->{symbtab}->Lookup($name);
	if (defined $node) {
	 	if (	    ! $node->isa($class)
	 			and ! $node->isa('StructType')
	 			and ! $node->isa('UnionType')
	 			and ! $node->isa('ForwardStructType')
	 			and ! $node->isa('ForwardUnionType')
	 			and ! $node->isa('EnumType')
	 			and ! $node->isa('Interface')
	 			and ! $node->isa('ForwardInterface')
	 			and ! $node->isa('RegularValue')
	 			and ! $node->isa('BoxedValue')
	 			and ! $node->isa('AbstractValue')
	 			and ! $node->isa('ForwardRegularValue')
	 			and ! $node->isa('ForwardAbstractValue') ) {
			$parser->Error("'$name' is not a type nor a value.\n");
		}
	}
	return $node;
}

sub CheckDeprecated {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser,$type) = @_;
	if (		defined $type
			and $parser->YYData->{IDL_version} ge '2.4' ) {
		if (	   $type->isa('StringType')
				or $type->isa('WideStringType') ) {
			if (exists $type->{max}) {
				$parser->Deprecated("Anonymous type.\n");
			}
		} elsif	(  $type->isa('FixedPtType') ) {
			if (exists $type->{d}) {
				$parser->Deprecated("Anonymous type.\n");
			}
		} elsif	(  $type->isa('SequenceType') ) {
			$parser->Deprecated("Anonymous type.\n");
		}
	}
}

sub CheckForward {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser,$type) = @_;
	while (		defined $type
			and (  $type->isa('SequenceType')
				or (   $type->isa('TypeDeclarator')
				   and ! exists $type->{array_size} ) ) ) {
		last if (exists $type->{modifier});		# native
		$type = $type->{type};
	}
	if (		defined $type
			and (  $type->isa('ForwardStructType')
				or $type->isa('ForwardUnionType') ) ) {
		if (! exists $type->{fwd}) {
			$parser->Error("'$type->{idf}' is declared, but not defined.\n");
		}
	}
}

package TypeDeclarators;

@TypeDeclarators::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	my @list;
	foreach (@{$self->{list_expr}}) {
		my @array_size = @{$_};
		my $idf = shift @array_size;
		my $decl;
		if (@array_size) {
			$decl = new TypeDeclarator($parser,
					type				=>	$self->{type},
					idf					=>	$idf,
					array_size			=>	\@array_size
			);
			TypeDeclarator->CheckDeprecated($parser,$self->{type});
		} else {
			$decl = new TypeDeclarator($parser,
					type				=>	$self->{type},
					idf					=>	$idf
			);
		}
		push @list, $decl;
	}
	$self->configure(list_value	=>	\@list);
	$self->line_stamp($parser);
	return $self;
}

#
#	3.10.1	Basic Types
#

package BasicType;

@BasicType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

sub visit {
	my $self = shift;
	my($visitor) = @_;
	$visitor->visitBasicType($self);
}

sub visitName {
	my $self = shift;
	my $class = ref $self;
	my $visitor = shift;
	return $visitor->visitNameBasicType($self,@_);
}

package FloatingPtType;

@FloatingPtType::ISA = qw(BasicType);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new BasicType(@_);
	bless($self, $class);
	return $self;
}

package IntegerType;

@IntegerType::ISA = qw(BasicType);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new BasicType(@_);
	bless($self, $class);
	return $self;
}

package CharType;

@CharType::ISA = qw(BasicType);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new BasicType(@_);
	bless($self, $class);
	return $self;
}

package WideCharType;

@WideCharType::ISA = qw(BasicType);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new BasicType(@_);
	bless($self, $class);
	return $self;
}

package BooleanType;

@BooleanType::ISA = qw(BasicType);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new BasicType(@_);
	bless($self, $class);
	return $self;
}

package OctetType;

@OctetType::ISA = qw(BasicType);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new BasicType(@_);
	bless($self, $class);
	return $self;
}

package AnyType;

@AnyType::ISA = qw(BasicType);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new BasicType(@_);
	bless($self, $class);
	return $self;
}

package ObjectType;

@ObjectType::ISA = qw(BasicType);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = new BasicType(@_);
	bless($self, $class);
	return $self;
}

package ValueBaseType;

@ValueBaseType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

#
#	3.10.2	Constructed Types
#
#	3.10.2.1	Structures
#

package StructType;

@StructType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{symbtab}->Insert($self->{idf},new Dummy($self));
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my @list;
	foreach (@{$self->{list_expr}}) {
		foreach (@{$_->{list_value}}) {
			push @list, $_;
		}
	}
	$self->configure(list_value	=>	\@list);	# list of 'Single' or 'Array'
	return $self;
}

package Members;

@Members::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	my @list;
	foreach (@{$self->{list_expr}}) {
		my $member;
		my @array_size = @{$_};
		my $idf = shift @array_size;
		if (@array_size) {
			$member = new Array($parser,
					type			=>	$self->{type},
					idf				=>	$idf,
					array_size		=>	\@array_size
			);
			if ($parser->YYData->{IDL_version} ge '2.4') {
				$parser->Deprecated("Anonymous type (array).\n");
			}
		} else {
			$member = new Single($parser,
					type			=>	$self->{type},
					idf				=>	$idf,
			);
		}
		push @list, $member;
	}
	$self->configure(list_value	=>	\@list);
	TypeDeclarator->CheckDeprecated($parser,$self->{type});
	TypeDeclarator->CheckForward($parser,$self->{type});
	return $self;
}

package Array;							# idf, type, array_size

@Array::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

package Single;							# idf, type

@Single::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

#	3.10.2.2	Discriminated Unions
#

package UnionType;

@UnionType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{symbtab}->Insert($self->{idf},new Dummy($self));
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my $type = $self->{type};
	if ($type->isa('TypeDeclarator')) {
		$type = $type->{type};
		if (		! $type->isa('IntegerType')
				and ! $type->isa('CharType')
				and ! $type->isa('BooleanType')
				and ! $type->isa('EnumType') ) {
			$parser->Error("'$type->{idf}' refers a bad type for union.\n");
			return $self;
		}
	}
	my %hash;
	foreach (@{$self->{list_expr}}) {
		my $elt = $_->{element};
		my @list;
		foreach (@{$_->{list_label}}) {
			my $key;
			if (ref $_ eq 'Default') {
				$key = 'Default';
				push @list, $_;
			} else {
				# now, type is known
				my $cst = new Expression($parser,
						type				=>	$type,
						list_expr			=>	$_
				);
				$key = $cst->{value};
				push @list, $cst;
			}
			if (defined $key) {
				if (exists $hash{$key}) {
					$parser->Error("label value '$key' is duplicate for union.\n");
				} else {
					$hash{$key} = $elt;
				}
			}
		}
		$_->{list_label} = \@list;
	}
	$self->configure(hash_value	=>	\%hash);
	return $self;
}

package Case;

@Case::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

package Default;

@Default::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

package Element;

@Element::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	TypeDeclarator->CheckDeprecated($parser,$self->{type});
	TypeDeclarator->CheckForward($parser,$self->{type});
	my @array_size = @{$self->{list_expr}};
	my $idf = shift @array_size;
	my $value;
	if (@array_size) {
		if ($parser->YYData->{IDL_version} ge '2.4') {
			$parser->Deprecated("Anonymous type (array).\n");
		}
		$value = new Array($parser,
				type			=>	$self->{type},
				idf				=>	$idf,
				array_size		=>	\@array_size
		);
	} else {
		$value = new Single($parser,
				type			=>	$self->{type},
				idf				=>	$idf,
		);
	}
	$self->configure(value	=>	$value);	# 'Array' or 'Single'
	return $self;
}

#	3.10.2.3	Enumerations
#

package EnumType;

use constant ULONG_MAX		=> 4294967295;

@EnumType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my $idx = 0;						# Section 15.3 CDR Transfer Syntax
										# 15.3.2.6 Enum
	my %hash;
	my @list;
	foreach (@{$self->{list_expr}}) {
		if (exists $hash{$_->{idf}}) {
			$parser->Error("enum '$_->{idf}' is duplicate.\n");
		} else {
			$hash{$_->{idf}} = $idx;
			push @list, $_;
		}
		$_->configure(
				type		=>	$self,
				value		=>	"$idx"
		);
		$idx++;
	}
	$self->configure(list_value	=>	\@list);	# list of 'Enum'
	if ($idx > ULONG_MAX) {
		$parser->Error("too many enum for '$self->{type}'.\n");
	}
	return $self;
}

package Enum;

@Enum::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

#
#	3.10.3	Constructed Recursive Types and Forward Declarations
#

package ForwardStructType;

@ForwardStructType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->InsertForward($self->{idf},$self);
	$self->line_stamp($parser);
	return $self;
}

package ForwardUnionType;

@ForwardUnionType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->InsertForward($self->{idf},$self);
	$self->line_stamp($parser);
	return $self;
}

#
#	3.10.4	Template Types
#

package SequenceType;

@SequenceType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->line_stamp($parser);
	TypeDeclarator->CheckDeprecated($parser,$self->{type});
	return $self;
}

package StringType;

@StringType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

package WideStringType;

@WideStringType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

package FixedPtType;

@FixedPtType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->line_stamp($parser);
	return $self;
}

#
#	3.11	Exception Declaration
#

package Exception;

@Exception::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{symbtab}->Insert($self->{idf},new Dummy($self));
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

sub Lookup {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser,$name) = @_;
	my $node = $parser->YYData->{symbtab}->Lookup($name);
	if (defined $node
	 && ! $node->isa($class) ) {
		$parser->Error("'$name' is not a $class.\n");
	}
	return $node;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my @list;
	foreach (@{$self->{list_expr}}) {
		foreach (@{$_->{list_value}}) {
			push @list, $_;
		}
	}
	$self->configure(list_value	=>	\@list);	# list of 'Single' or 'Array'
	return $self;
}

#
#	3.12	Operation Declaration
#

package Operation;

@Operation::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	$parser->YYData->{unnamed_symbtab} = new UnnamedSymbtab($parser);
	$self->line_stamp($parser);
	my $type = $self->{type};
	TypeDeclarator->CheckDeprecated($parser,$type);
	TypeDeclarator->CheckForward($parser,$type);
	if (defined $parser->YYData->{curr_itf}) {
		$self->{itf} = $parser->YYData->{curr_itf}->{coll};
		$parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self;
	} else {
		$parser->Error(__PACKAGE__,"::new ERROR_INTERNAL.\n");
	}
	if (exists $type->{idf}) {
		$parser->YYData->{unnamed_symbtab}->InsertUsed($type->{idf});
	}
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

sub _CheckOneway {
	my $self = shift;
	my($parser) = @_;
	if (exists $self->{modifier} and $self->{modifier} eq 'oneway') {
		# 3.12.1	Operation Attribute
		if (! $self->{type}->isa('VoidType')) {
			$parser->Error("return type of '$self->{idf}' is not 'void'.\n");
		}
		foreach ( @{$self->{list_param}} ) {
			if ($_->{attr} ne 'in') {
				$parser->Error("parameter '$_->{idf}' is not 'in'.\n");
			}
		}
		if (exists $self->{list_raise}) {
			$parser->Error("oneway operation can't raise exception.\n");
		}
	}
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	$self->_CheckOneway($parser);
	my @list_in = ();
	my @list_inout = ();
	my @list_out = ();
	foreach ( @{$self->{list_param}} ) {
		if      ($_->{attr} eq 'in') {
			push @list_in, $_;
		} elsif ($_->{attr} eq 'inout') {
			push @list_inout, $_;
		} elsif ($_->{attr} eq 'out') {
			push @list_out, $_;
		}
	}
	$self->{list_in} = \@list_in;
	$self->{list_inout} = \@list_inout;
	$self->{list_out} = \@list_out;
	return $self;
}

package Parameter;

@Parameter::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$self->line_stamp($parser);
	my $type = $self->{type};
	TypeDeclarator->CheckDeprecated($parser,$type);
	TypeDeclarator->CheckForward($parser,$type);
	if (exists $type->{idf}) {
		$parser->YYData->{unnamed_symbtab}->InsertUsed($type->{idf});
	}
	$parser->YYData->{unnamed_symbtab}->Insert($self->{idf});
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

package VoidType;

@VoidType::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	return $self;
}

#
#	3.13	Attribute Declaration
#

package Attributes;

@Attributes::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	my @list;
	my @list_op;
	foreach (@{$self->{list_expr}}) {
		my $attr = new Attribute($parser,
				modifier			=>	$self->{modifier},
				type				=>	$self->{type},
				idf					=>	$_
		);
		push @list, $attr;
		my $op = new Operation($parser,
				type				=>	$self->{type},
				idf					=>	'_get_' . $_
		);
		$op->Configure($parser,
				list_param		=>	[]
		);
		push @list_op, $op;
		unless (exists $self->{modifier}) {		# readonly
			$op = new Operation($parser,
					type			=>	new VoidType($parser,
												value		=>	'void'
										),
					idf				=>	'_set_' . $_
			);
			# unnamed_symbtab created
			$op->Configure($parser,
					list_param		=>	[
											new Parameter($parser,
													attr	=>	'in',
													type	=>	$self->{type},
													idf		=>	$_
											)
										]
			);
			push @list_op, $op;
		}
	}
	$self->configure(
			list_value	=>	\@list,		# attribute
			list_op		=>	\@list_op	# operation
	);
	$self->line_stamp($parser);
	return $self;
}

package Attribute;

@Attribute::ISA = qw(node);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = new node(@_);
	bless($self, $class);
	# specific
	$parser->YYData->{symbtab}->Insert($self->{idf},$self);
	if (defined $parser->YYData->{curr_itf}) {
	    $parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self;
	} else {
		$parser->Error(__PACKAGE__,"::new ERROR_INTERNAL.\n");
	}
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	return $self;
}

1;

