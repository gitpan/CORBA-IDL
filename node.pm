use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v3.0)
#

package node;
use vars qw($VERSION);
$VERSION = '2.05';

sub _Build {
	my $proto = shift;
	my %attr = @_;
	my $self = \%attr;
	foreach (keys %attr) {
		unless (defined $self->{$_}) {
			delete $self->{$_};
		}
	}
	return $self;
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parser = shift;
	my $self = _Build node(@_);
	bless($self, $class);
	$self->_Init($parser);		# specialized or default
	return $self
}

sub _Init {
	# default
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

sub getRef {
	my $self = shift;
	if (exists $self->{full}) {
		if (	   ref($self) eq 'Module'
				or ref($self) =~ /^Forward/ ) {
			return $self;
		} else {
			return $self->{full};
		}
	} else {
		return $self;
	}
}

sub getInheritance {
	my $self = shift;
	my @list = ();
	if (exists $self->{inheritance}) {
		if (exists $self->{inheritance}->{list_interface}) {
			push @list, @{$self->{inheritance}->{list_interface}};
		}
		if (exists $self->{inheritance}->{list_value}) {
			push @list, @{$self->{inheritance}->{list_value}};
		}
	}
	return @list;
}

sub visit {
	# overloaded in : BasicType, Literal
	my $self = shift;
	my $class = ref $self;
	my $visitor = shift;
	my $func = 'visit' . $class;
	if($visitor->can($func)) {
		$visitor->$func($self,@_);
	} else {
		warn "Please implement a function '$func' in '",ref $visitor,"'.\n";
	}
}

sub visitName {
	# overloaded in : BasicType, BaseInterface
	my $self = shift;
	my $class = ref $self;
	my $visitor = shift;
	my $func = 'visitName' . $class;
	if($visitor->can($func)) {
		return $visitor->$func($self,@_);
	} else {
		warn "Please implement a function '$func' in '",ref $visitor,"'.\n";
		return undef;
	}
}

#
#	3.5		OMG IDL Specification
#

package Specification;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	my %hash;
	foreach my $export (@{$self->{list_decl}}) {
		if (ref $export) {
			unless (ref($export) =~ /^Forward/) {
				if ($export->isa('Module')) {
					$hash{$export->{full}} = 1;
				} else {	# TypeDeclarators, StateMembers, Attributes
					foreach (@{$export->{list_decl}}) {
						$hash{$_} = 1 if (defined $_);
					}
				}
			}
		} else {
			$hash{$export} = 1;
		}
	}
	$self->{list_export} = [keys %hash];
	$parser->YYData->{symbtab}->Insert($self);
}

#
#	3.6		Import Declaration
#

package Import;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$parser->YYData->{symbtab}->Import($self);
}

#
#	3.7		Module Declaration
#

package Modules;

use base qw(node);

package Module;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc}
				unless (exists $self->{doc});
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{symbtab}->PushCurrentRoot($self);
	$parser->YYData->{curr_node} = $self;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my $defn = $parser->YYData->{symbtab}->Lookup($self->{full});	# Modules
	my %hash;
	foreach my $module (@{$defn->{list_decl}}) {
		foreach my $export (@{$module->{list_decl}}) {
			if (ref $export) {
				unless (ref($export) =~ /^Forward/) {
					if ($export->isa('Module')) {
						$hash{$export->{full}} = 1;
					} else {	# TypeDeclarators, StateMembers, Attributes
						foreach (@{$export->{list_decl}}) {
							$hash{$_} = 1 if (defined $_);
						}
					}
				}
			} else {
				$hash{$export} = 1;
			}
		}
	}
	$defn->{list_export} = [keys %hash];
	return $defn;
}

#
#	3.8		Interface Declaration
#

package BaseInterface;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$self->{local_type} = 1 if ($self->isa('LocalInterface'));
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{curr_itf} = $self;
	$self->_CheckInheritance($parser);			# specialized
	$self->_InsertInherited($parser);
	$parser->YYData->{curr_node} = $self;
}

sub _InsertInherited {
	my $self = shift;
	my ($parser) = @_;
	$self->{hash_attribute_operation} = {};
	foreach ($self->getInheritance()) {
		my $base = $parser->YYData->{symbtab}->Lookup($_);
		foreach (keys %{$base->{hash_attribute_operation}}) {
			next if ($_->isa('Initializer'));
#			next if ($_->isa('Factory'));
#			next if ($_->isa('Finder'));
			my $name = $base->{hash_attribute_operation}{$_};
			if (exists $self->{hash_attribute_operation}{$_}) {
				if ($self->{hash_attribute_operation}{$_} ne $name) {
					$parser->Error("multi inheritance of '$_'.\n");
				}
			} else {
				$self->{hash_attribute_operation}{$_} = $name;
				$parser->YYData->{symbtab}->InsertInherit($self, $_, $name);
			}
		}
	}
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my @list;
	foreach my $export (@{$self->{list_decl}}) {
		if (ref $export) {
			unless (ref($export) =~ /^Forward/) {
				foreach (@{$export->{list_decl}}) {
					push @list, $_ if (defined $_);
				}
			}
		} else {
			push @list, $export;
		}
	}
	$self->{list_export} = \@list;
	$self->_CheckLocal($parser);			# specialized
	return $self;
}

sub Lookup {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser,$name) = @_;
	my $defn = $parser->YYData->{symbtab}->Lookup($name);
	if (defined $defn) {
	 	if ($defn->isa('Forward' . $class)) {
			$parser->Error("'$name' is declared, but not defined.\n");
	 	} elsif (! $defn->isa($class)) {
			$parser->Error("'$name' is not a $class.\n");
		}
		return $defn->{full};
	} else {
		return '';
	}
}

sub visitName {
	my $self = shift;
	my $class = ref $self;
	my $visitor = shift;
	my $func = 'visitName' . $class;
	if ($visitor->can($func)) {
		return $visitor->$func($self,@_);
	} else {
		return $visitor->visitNameBaseInterface($self,@_);
	}
}

#
#	3.8.2	Interface Inheritance Specification
#

package InheritanceSpec;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{hash_interface} = {};
	my %hash;
	# 3.8.5	Interface Inheritance
	if (exists $self->{list_interface}) {
		foreach my $name (@{$self->{list_interface}}) {
			if (exists $hash{$name}) {
				$parser->Warning("'$name' redeclares inheritance.\n");
			} else {
				$hash{$name} = 1;
				$self->{hash_interface}->{$name} = 1;
				my $base = $parser->YYData->{symbtab}->Lookup($name);
				foreach (keys %{$base->{inheritance}->{hash_interface}}) {
					$self->{hash_interface}->{$_} = 1;
				}
			}
		}
	}
	# 3.9.5	Valuetype Inheritance
	if (exists $self->{list_value}) {
		foreach my $name (@{$self->{list_value}}) {
			if (exists $hash{$name}) {
				$parser->Warning("'$name' redeclares inheritance.\n");
			} else {
				$hash{$name} = 1;
				$self->{hash_interface}->{$name} = 1;
				my $base = $parser->YYData->{symbtab}->Lookup($name);
				foreach (keys %{$base->{inheritance}->{hash_interface}}) {
					$self->{hash_interface}->{$_} = 1;
				}
			}
		}
	}
}

package Interface;

use base qw(BaseInterface);

package RegularInterface;

use base qw(Interface);

sub _CheckInheritance {
	my $self = shift;
	my($parser) = @_;
	if (exists $self->{inheritance}) {
		foreach (@{$self->{inheritance}->{list_interface}}) {
			my $base = $parser->YYData->{symbtab}->Lookup($_);
			# An unconstrained interface may not inherit from a local interface.
			if ($base->isa('LocalInterface')) {
				$parser->Error("'$self->{idf}' is not local.\n");
			}
		}
	}
}

sub _CheckLocal {
	my $self = shift;
	my($parser) = @_;

	# A local type may not appear as a parameter, attribute, return type, or exception
	# declaration of an unconstrained interface or as a state member of a valuetype.
	foreach (@{$self->{list_export}}) {
		my $defn = $parser->YYData->{symbtab}->Lookup($_);
		if      ($defn->isa('Attribute')) {
			if (TypeDeclarator->IsaLocal($parser, $defn->{type})) {
				$parser->Error("'$self->{idf}' is not local.\n");
			}
		} elsif ($defn->isa('Operation')) {
			if (TypeDeclarator->IsaLocal($parser, $defn->{type})) {
				$parser->Error("'$self->{idf}' is not local.\n");
			}
			foreach (@{$defn->{list_param}}) {
				if (TypeDeclarator->IsaLocal($parser, $_->{type})) {
					$parser->Error("'$self->{idf}' is not local.\n");
				}
			}
		}
	}
}

#
#	3.8.4	Forward Declaration
#

package ForwardBaseInterface;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$self->line_stamp($parser);
	$self->{local_type} = 1 if ($self->isa('ForwardLocalInterface'));
	$parser->YYData->{symbtab}->InsertForward($self);
}

package ForwardInterface;

use base qw(ForwardBaseInterface);

package ForwardRegularInterface;

use base qw(ForwardInterface);

package ForwardAbstractInterface;

use base qw(ForwardInterface);

package ForwardLocalInterface;

use base qw(ForwardInterface);

#
#	3.8.6	Abstract Interface
#

package AbstractInterface;

use base qw(Interface);

sub _CheckInheritance {
	my $self = shift;
	my($parser) = @_;
	if (exists $self->{inheritance}) {
		foreach (@{$self->{inheritance}->{list_interface}}) {
			my $base = $parser->YYData->{symbtab}->Lookup($_);
			# (An unconstrained interface may not inherit from a local interface.)
			# An abstract interface may only inherit from other abstract interfaces.
			unless ($base->isa('AbstractInterface')) {
				$parser->Error("'$_' is not abstract.\n");
			}
		}
	}
}

sub _CheckLocal {
	my $self = shift;
	my($parser) = @_;

	# A local type may not appear as a parameter, attribute, return type, or exception
	# declaration of an unconstrained interface or as a state member of a valuetype.
	foreach (@{$self->{list_export}}) {
		my $defn = $parser->YYData->{symbtab}->Lookup($_);
		if      ($defn->isa('Attribute')) {
			if (TypeDeclarator->IsaLocal($parser, $defn->{type})) {
				$parser->Error("'$self->{idf}' is not local.\n");
			}
		} elsif ($defn->isa('Operation')) {
			if (TypeDeclarator->IsaLocal($parser, $defn->{type})) {
				$parser->Error("'$self->{idf}' is not local.\n");
			}
			foreach (@{$defn->{list_param}}) {
				if (TypeDeclarator->IsaLocal($parser, $_->{type})) {
					$parser->Error("'$self->{idf}' is not local.\n");
				}
			}
		}
	}
}

#
#	3.8.7	Local Interface
#

package LocalInterface;

use base qw(Interface);

sub _CheckInheritance {
	# A local interface may inherit from other local or unconstrained interfaces
}

sub _CheckLocal {
	# Any IDL type, including an unconstrained interface, may appear as a parameter,
	# attribute, return type, or exception declaration of a local interface.

	# A local type may be used as a parameter, attribute, return type, or exception
	# declaration of a local interface or of a valuetype.
}

#
#	3.9		Value Declaration
#

package Value;

use base qw(BaseInterface);

#	3.9.1	Regular Value Type
#

package RegularValue;

use base qw(Value);

sub _CheckInheritance {
	my $self = shift;
	my($parser) = @_;
	if (exists $self->{inheritance}) {
		if (    exists $self->{inheritance}->{modifier}		# truncatable
			and exists $self->{modifier} ) {				# custom
			$parser->Error("'truncatable' is used in a custom value.\n");
		}
	}
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->SUPER::Configure($parser,@_);
	my @list;
	foreach my $value_element (@{$self->{list_decl}}) {
		next unless (ref $value_element eq 'StateMembers');
		foreach (@{$value_element->{list_decl}}) {
			push @list, $_;
		}
	}
	$self->configure(list_value		=>	\@list);	# list of 'StateMember'
	return $self;
}

sub _CheckLocal {
	# A local type may be used as a parameter, attribute, return type, or exception
	# declaration of a local interface or of a valuetype.
}

#
#	3.9.1.4	State Members
#

package StateMembers;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	my @list;
	foreach (@{$self->{list_expr}}) {
		my $member;
		my @array_size = @{$_};
		my $idf = shift @array_size;
		if (@array_size) {
			$member = new StateMember($parser,
					modifier		=>	$self->{modifier},
					type			=>	$self->{type},
					idf				=>	$idf,
					array_size		=>	\@array_size
			);
			if ($Parser::IDL_version ge '2.4') {
				$parser->Deprecated("Anonymous type (array).\n");
			}
		} else {
			$member = new StateMember($parser,
					modifier		=>	$self->{modifier},
					type			=>	$self->{type},
					idf				=>	$idf,
			);
		}
		push @list, $member->{full};
	}
	$self->configure(list_decl	=>	\@list);
	TypeDeclarator->CheckDeprecated($parser,$self->{type});
	TypeDeclarator->CheckForward($parser,$self->{type});
	# A local type may not appear as a parameter, attribute, return type, or exception
	# declaration of an unconstrained interface or as a state member of a valuetype.
	if (TypeDeclarator->IsaLocal($parser, $self->{type})) {
		my $idf = $self->{type}->{idf} if (exists $self->{type}->{idf});
		$idf ||= $self->{type};
		$parser->Error("'$idf' is local.\n");
	}
}

package StateMember;					# modifier, idf, type[, array_size]

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$parser->YYData->{symbtab}->Insert($self);
	if (defined $parser->YYData->{curr_itf}) {
		$parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full}
	} else {
		$parser->Error(__PACKAGE__ . "::new ERROR_INTERNAL.\n");
	}
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{curr_node} = $self;
}

#
#	3.9.1.5	Initializers
#

package Initializer;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$parser->YYData->{symbtab}->Insert($self);
	$parser->YYData->{unnamed_symbtab} = new UnnamedSymbtab($parser);
	if (defined $parser->YYData->{curr_itf}) {
		$self->{itf} = $parser->YYData->{curr_itf}->{full};
		$parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full}
	} else {
		$parser->Error(__PACKAGE__ . "::new ERROR_INTERNAL.\n");
	}
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{curr_node} = $self;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my @list_in = ();
	foreach ( @{$self->{list_param}} ) {
		if      ($_->{attr} eq 'in') {
			unshift @list_in, $_;
		}
	}
	$self->{list_in} = \@list_in;
	$self->{list_inout} = [];
	$self->{list_out} = [];
	return $self;
}

#
#	3.9.2	Boxed Value Type
#
package BoxedValue;

use base qw(Value);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{curr_itf} = $self;
	$parser->YYData->{curr_node} = $self;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my $type = TypeDeclarator->GetDefn($parser, $self->{type});
	if ($type->isa('Value')) {
		if ($Parser::IDL_version ge '3.0') {
			$parser->Error("$self->{type}->{idf} is a value type.\n");
		} else {
			$parser->Info("$self->{type}->{idf} is a value type.\n");
		}
	}
	return $self;
}

#
#	3.9.3	Abstract Value Type
#

package AbstractValue;

use base qw(Value);

sub _CheckInheritance {
	# empty
}

sub _CheckLocal {
	# A local type may be used as a parameter, attribute, return type, or exception
	# declaration of a local interface or of a valuetype.
}

#
#	3.9.4	Value Forward Declaration
#

package ForwardValue;

use base qw(ForwardBaseInterface);

package ForwardRegularValue;

use base qw(ForwardValue);

package ForwardAbstractValue;

use base qw(ForwardValue);

#
#	3.10		Constant Declaration
#

package Expression;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	if (        ! exists $self->{type} ) {
		$self->configure(
				type	=>	new IntegerType($parser,
									value	=>	'unsigned long',
									auto	=>	1
							)
		);
	} elsif (   @{$self->{list_expr}} == 1
			and defined $self->{list_expr}[0] ) {
		if (ref $self->{type}) {
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
	}
	$self->configure(
			value	=>	$self->Eval($parser)
	);
}

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

sub Eval {
	my $self = shift;
	my($parser) = @_;
	my @list_expr = @{$self->{list_expr}};		# create a copy
	my $type = TypeDeclarator->GetEffectiveType($parser, $self->{type});
	if (defined $type) {
		return _Eval($parser, $type, \@list_expr);
	} else {
		return 0;
	}
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
			my $value = new Math::BigInt($left->bior($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '^' ) {
			my $value = new Math::BigInt($left->bxor($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '&' ) {
			my $value = new Math::BigInt($left->band($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '+' ) {
			my $value = new Math::BigInt($left->badd($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '-' ) {
			my $value = new Math::BigInt($left->bsub($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '*' ) {
			my $value = new Math::BigInt($left->bmul($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '/' ) {
			my $value = new Math::BigInt($left->bdiv($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '%' ) {
			my $value = new Math::BigInt($left->bmod($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '>>' ) {
			if (0 <= $right and $right < 64) {
				my $value = new Math::BigInt($left->brsft($right));
				return _CheckRange($parser,$type,$value);
			} else {
				$parser->Error("shift operation out of range.\n");
				return undef;
			}
		} elsif ( $elt->{op} eq '<<' ) {
			if (0 <= $right and $right < 64) {
				my $value = new Math::BigInt($left->blsft($right));
				return _CheckRange($parser,$type,$value);
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
			my $value = new Math::BigFloat($left->fadd($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '-' ) {
			my $value = new Math::BigFloat($left->fsub($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '*' ) {
			my $value = new Math::BigFloat($left->fmul($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '/' ) {
			my $value = new Math::BigFloat($left->fdiv($right));
			return _CheckRange($parser,$type,$value);
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
	} elsif (  $type->isa('FixedPtConstType') ) {
		my $right = _Eval($parser,$type,$list_expr);
		return undef unless (defined $right);
		my $left = _Eval($parser,$type,$list_expr);
		return undef unless (defined $left);
		if (      $elt->{op} eq '+' ) {
			my $value = new Math::BigFloat($left->fadd($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '-' ) {
			my $value = new Math::BigFloat($left->fsub($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '*' ) {
			my $value = new Math::BigFloat($left->fmul($right));
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '/' ) {
			my $value = new Math::BigFloat($left->fdiv($right));
			return _CheckRange($parser,$type,$value);
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
			my $value = new Math::BigInt($right->bneg());
			return _CheckRange($parser,$type,$value);
		} elsif ( $elt->{op} eq '~' ) {
			my $value = new Math::BigInt($right->bnot());
			return _CheckRange($parser,$type,$value);
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
			my $value = new Math::BigFloat($right->fneg());
			return _CheckRange($parser,$type,$value);
		} elsif (  $elt->{op} eq '~' ) {
			$parser->Error("'$elt->{op}' is not valid for '$type'.\n");
			return undef;
		} else {
			$parser->Error("_EvalUnop (fp) : INTERNAL ERROR.\n");
			return undef;
		}
	} elsif (  $type->isa('FixedPtConstType') ) {
		my $right = _Eval($parser,$type,$list_expr);
		return undef unless (defined $right);
		if (	  $elt->{op} eq '+' ) {
			return _CheckRange($parser,$type,$right);
		} elsif ( $elt->{op} eq '-' ) {
			my $value = new Math::BigFloat($right->fneg());
			return _CheckRange($parser,$type,$value);
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
	my ($parser, $type, $list_expr) = @_;
	my $elt = pop @$list_expr;
	return undef unless (defined $elt);
	return undef unless ($elt);
	unless (ref $elt) {
		$elt = $parser->YYData->{symbtab}->Lookup($elt);
		return undef unless (defined $elt);
	}
	if      ($elt->isa('BinaryOp'))	{
		return _EvalBinop($parser,$type,$elt,$list_expr);
	} elsif ($elt->isa('UnaryOp')) {
		return _EvalUnop($parser,$type,$elt,$list_expr);
	} elsif ($elt->isa('Constant')) {
		if (ref $type eq ref $elt->{value}->{type}) {
			return _CheckRange($parser,$type,$elt->{value}->{value});
		} elsif ($type->isa('IntegerType') and $elt->{value}->{type}->isa('OctetType')) {
			return _CheckRange($parser,$type,$elt->{value}->{value});
		} else {
			$parser->Error("'$elt->{value}->{value}' is not a '$type->{value}'.\n");
			return undef;
		}
	} elsif ($elt->isa('Enum')) {
		if ($type eq $parser->YYData->{symbtab}->Lookup($elt->{type})) {
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
		if ($type->isa('FixedPtConstType')) {
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
	} elsif (  $type->isa('FixedPtConstType') ) {
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

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$parser->YYData->{symbtab}->Insert($self);
	my $type = $self->{type};
	TypeDeclarator->CheckDeprecated($parser, $type);
	my $defn = TypeDeclarator->GetEffectiveType($parser, $type);
	if (defined $defn) {
		if (		! $defn->isa('IntegerType')
				and ! $defn->isa('CharType')
				and ! $defn->isa('WideCharType')
				and ! $defn->isa('BooleanType')
				and ! $defn->isa('FloatingPtType')
				and ! $defn->isa('StringType')
				and ! $defn->isa('WideStringType')
				and ! $defn->isa('FixedPtConstType')
				and ! $defn->isa('OctetType')
				and ! $defn->isa('EnumType') ) {
			my $idf = $defn->{idf} if (exists $defn->{idf});
			$idf ||= $type->{idf} if (exists $type->{idf});
			$idf ||= $type;
			$parser->Error("'$idf' refers a bad type for constant.\n");
			return $self;
		}
	} else {
		$parser->Error(__PACKAGE__ . "::_Init ERROR_INTERNAL ($type).\n");
	}
	$self->configure(
			value	=>	new Expression($parser,
								type		=>	$defn,
								list_expr	=>	$self->{list_expr}
						)
	);
	$parser->YYData->{curr_node} = $self;
}

sub Lookup {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser,$name) = @_;
	my $defn = $parser->YYData->{symbtab}->Lookup($name);
	if (defined $defn) {
	 	if (		! $defn->isa($class)
	 			and ! $defn->isa('Enum') ) {
			$parser->Error("'$name' is not a $class.\n");
		}
		return $defn->{full};
	} else {
		return '';
	}
}

package UnaryOp;

use base qw(node);

package BinaryOp;

use base qw(node);

#
#	3.2.5	Literals
#

package Literal;

use base qw(node);

sub visit {
	my $self = shift;
	my $class = ref $self;
	my $visitor = shift;
	my $func = 'visit' . $class;
	if($visitor->can($func)) {
		$visitor->$func($self,@_);
	} else {
		$visitor->visitLiteral($self,@_);
	}
}

package IntegerLiteral;

use base qw(Literal);

package StringLiteral;

use base qw(Literal);

package WideStringLiteral;

use base qw(Literal);

package CharacterLiteral;

use base qw(Literal);

package WideCharacterLiteral;

use base qw(Literal);

package FixedPtLiteral;

use base qw(Literal);

package FloatingPtLiteral;

use base qw(Literal);

package BooleanLiteral;

use base qw(Literal);

#
#	3.11	Type Declaration
#

package TypeDeclarator;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{symbtab}->Insert($self);
	$parser->YYData->{curr_node} = $self;
	if (exists $self->{type}) {
		$self->{local_type} = 1 if (TypeDeclarator->IsaLocal($parser, $self->{type}));
	}
}

sub Lookup {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser, $name) = @_;
	my $defn = $parser->YYData->{symbtab}->Lookup($name);
	if (defined $defn) {
		if (	    ! $defn->isa($class)
				and ! $defn->isa('_ConstructedType')
				and ! $defn->isa('_ForwardConstructedType')
				and ! $defn->isa('BaseInterface')
				and ! $defn->isa('ForwardBaseInterface') ) {
			$parser->Error("'$name' is not a type nor a value.\n");
		}
		return $defn->{full};
	} else {
		return '';
	}
}

sub GetDefn {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser, $type) = @_;
	return undef unless ($type);
	if (ref $type) {
		return $type;
	} else {
		my $defn = $parser->YYData->{symbtab}->Lookup($type);
		return $defn;
	}
}

sub GetEffectiveType {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser, $type) = @_;
	my $defn = TypeDeclarator->GetDefn($parser, $type);
	unless (defined $defn) {
		$parser->Error(__PACKAGE__ . "::GetEffectiveType ERROR_INTERNAL ($type).\n");
		return undef;
	}
	while (	    $defn->isa('TypeDeclarator')
			and ! exists $defn->{array_size} ) {
		$defn = TypeDeclarator->GetDefn($parser, $defn->{type});
		unless (defined $defn) {
			$parser->Error(__PACKAGE__ . "::GetEffectiveType ERROR_INTERNAL ($defn->{type}).\n");
			return undef;
		}
	}
	return $defn;
}

sub CheckDeprecated {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser, $type) = @_;
	my $defn = TypeDeclarator->GetDefn($parser, $type);
	return unless (defined $defn);
	if ($Parser::IDL_version ge '2.4') {
		if (	   $defn->isa('StringType')
				or $defn->isa('WideStringType') ) {
			if (exists $defn->{max}) {
				$parser->Deprecated("Anonymous type.\n");
			}
		} elsif	(  $defn->isa('FixedPtType') ) {
			$parser->Deprecated("Anonymous type.\n");
		} elsif	(  $defn->isa('SequenceType') ) {
			$parser->Deprecated("Anonymous type.\n");
		}
	}
}

sub CheckForward {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my($parser, $type) = @_;
	my $defn = TypeDeclarator->GetDefn($parser, $type);
	return unless (defined $defn);
	while (		   $defn->isa('SequenceType')
				or $defn->isa('TypeDeclarator') ) {
		last if (exists $defn->{array_size});
		last if (exists $defn->{modifier});		# native
		$defn = TypeDeclarator->GetDefn($parser, $defn->{type});
		return unless (defined $defn);
	}
	if ($defn->isa('_ForwardConstructedType')) {
		$parser->Error("'$defn->{idf}' is declared, but not defined.\n");
	}
}

sub IsaLocal {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my($parser, $type) = @_;
	return undef unless ($type);
	my $defn = TypeDeclarator->GetDefn($parser, $type);
	return exists $defn->{local_type} if ($defn);
	$parser->Error(__PACKAGE__ . "::IsaLocal ERROR_INTERNAL ($type).\n");
	return undef;
}

package TypeDeclarators;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
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
		push @list, $decl->{full};
	}
	$self->configure(list_decl	=>	\@list);
}

#
#	3.11.1	Basic Types
#

package BasicType;

use base qw(node);

sub visit {
	my $self = shift;
	my $class = ref $self;
	my $visitor = shift;
	my $func = 'visit' . $class;
	if($visitor->can($func)) {
		$visitor->$func($self,@_);
	} else {
		$visitor->visitBasicType($self,@_);
	}
}

sub visitName {
	my $self = shift;
	my $class = ref $self;
	my $visitor = shift;
	my $func = 'visitName' . $class;
	if ($visitor->can($func)) {
		return $visitor->$func($self,@_);
	} else {
		return $visitor->visitNameBasicType($self,@_);
	}
}

package FloatingPtType;

use base qw(BasicType);

package IntegerType;

use base qw(BasicType);

package CharType;

use base qw(BasicType);

package WideCharType;

use base qw(BasicType);

package BooleanType;

use base qw(BasicType);

package OctetType;

use base qw(BasicType);

package AnyType;

use base qw(BasicType);

package ObjectType;

use base qw(BasicType);

package ValueBaseType;

use base qw(BasicType);

#
#	3.11.2	Constructed Types
#

package _ConstructedType;

use base qw(node);

#	3.11.2.1	Structures
#

package StructType;

use base qw(_ConstructedType);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{curr_node} = $self;
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
		$self->{local_type} = 1 if (TypeDeclarator->IsaLocal($parser, $_->{type}));
	}
	$self->configure(list_value	=>	\@list);	# list of 'Single' or 'Array'
	return $self;
}

package Members;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
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
			if ($Parser::IDL_version ge '2.4') {
				$parser->Deprecated("Anonymous type (array).\n");
			}
		} else {
			$member = new Single($parser,
					type			=>	$self->{type},
					idf				=>	$idf,
			);
		}
		push @list, $member->{full};
	}
	$self->configure(list_value	=>	\@list);
	TypeDeclarator->CheckDeprecated($parser,$self->{type});
	TypeDeclarator->CheckForward($parser,$self->{type});
}

package Array;							# idf, type, array_size

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$parser->YYData->{symbtab}->Insert($self);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{curr_node} = $self;
}

package Single;							# idf, type

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$parser->YYData->{symbtab}->Insert($self);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{curr_node} = $self;
}

#	3.11.2.2	Discriminated Unions
#

package UnionType;

use base qw(_ConstructedType);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{curr_node} = $self;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my $dis = $self->{type};
	my $defn = TypeDeclarator->GetEffectiveType($parser, $dis);
	if (defined $defn) {
		if (		! $defn->isa('IntegerType')
				and ! $defn->isa('CharType')
				and ! $defn->isa('BooleanType')
				and ! $defn->isa('EnumType') ) {
			my $idf = $defn->{idf} if (exists $defn->{idf});
			$idf ||= $dis->{idf} if (exists $dis->{idf});
			$idf ||= $dis;
			$parser->Error("'$idf' refers a bad type for union discriminator.\n");
			return $self;
		}
	}
	my %hash;
	my @list_all;
	foreach my $case (@{$self->{list_expr}}) {
		my $elt = $case->{element};
		$self->{local_type} = 1 if (TypeDeclarator->IsaLocal($parser, $elt->{type}));
		my @list;
		foreach (@{$case->{list_label}}) {
			my $key;
			if (ref $_ eq 'Default') {
				$key = 'Default';
				push @list, $_;
				$self->configure(default	=>	$case);
			} else {
				# now, type is known
				my $cst = new Expression($parser,
						type				=>	$dis,
						list_expr			=>	$_
				);
				$key = $cst->{value};
				push @list, $cst;
				push @list_all, $cst;
			}
			if (defined $key) {
				if (exists $hash{$key}) {
					$parser->Error("label value '$key' is duplicate for union.\n");
				} else {
					$hash{$key} = $elt;
				}
			}
		}
		$case->{list_label} = \@list;
	}
	$self->configure(list_value	=>	\@list_all);
	$self->configure(hash_value	=>	\%hash);
	if ($defn->isa('EnumType')) {
		my $all = 1;
		foreach (@{$defn->{list_value}}) {
			$all = 0 unless (exists $hash{$_});
		}
		if ($all) {
			$parser->Error("illegal label 'default'.\n")
					if (exists $self->{default});
		} else {
			$self->configure(need_default	=>	1)
					unless (exists $self->{default});
		}
	} else {
		$self->configure(need_default	=>	1)
				unless (exists $self->{default});
	}
	return $self;
}

package Case;

use base qw(node);

package Default;

use base qw(node);

package Element;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	TypeDeclarator->CheckDeprecated($parser,$self->{type});
	TypeDeclarator->CheckForward($parser,$self->{type});
	my @array_size = @{$self->{list_expr}};
	my $idf = shift @array_size;
	my $value;
	if (@array_size) {
		if ($Parser::IDL_version ge '2.4') {
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
	$self->configure(value	=>	$value->{full});	# 'Array' or 'Single'
}

#	3.11.2.3	Constructed Recursive Types and Forward Declarations
#

package _ForwardConstructedType;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$self->line_stamp($parser);
	$parser->YYData->{symbtab}->InsertForward($self);
}

package ForwardStructType;

use base qw(_ForwardConstructedType);

package ForwardUnionType;

use base qw(_ForwardConstructedType);

#	3.11.2.4	Enumerations
#

package EnumType;

use base qw(_ConstructedType);

use constant ULONG_MAX		=> 4294967295;

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{symbtab}->Insert($self);
	$parser->YYData->{curr_node} = $self;
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
			push @list, $_->{full};
		}
		$_->configure(
				type		=>	$self->{full},
				value		=>	"$idx"
		);
		$idx++;
	}
	$self->configure(list_value	=>	\@list);	# list of 'Enum'
	if ($idx > ULONG_MAX) {
		$parser->Error("too many enum for '$self->{idf}'.\n");
	}
	return $self;
}

package Enum;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{symbtab}->Insert($self);
	$parser->YYData->{curr_node} = $self;
}

#
#	3.11.3	Template Types
#

package _TemplateType;

use base qw(node);

package SequenceType;

use base qw(_TemplateType);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->line_stamp($parser);
	$parser->YYData->{symbtab}->InsertBogus($self);
	TypeDeclarator->CheckDeprecated($parser, $self->{type});
	$self->{local_type} = 1 if (TypeDeclarator->IsaLocal($parser, $self->{type}));
}

package StringType;

use base qw(_TemplateType);

package WideStringType;

use base qw(_TemplateType);

package FixedPtType;

use base qw(_TemplateType);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->line_stamp($parser);
}

package FixedPtConstType;

use base qw(_TemplateType);

#
#	3.12	Exception Declaration
#

package Exception;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
	$self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{symbtab}->PushCurrentScope($self);
	$parser->YYData->{curr_node} = $self;
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
		$self->{local_type} = 1 if (TypeDeclarator->IsaLocal($parser, $_->{type}));
	}
	$self->configure(list_value	=>	\@list);	# list of 'Single' or 'Array'
	return $self;
}

sub Lookup {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser, $name) = @_;
	my $defn = $parser->YYData->{symbtab}->Lookup($name);
	if (defined $defn) {
		unless ($defn->isa($class)) {
			$parser->Error("'$name' is not a $class.\n");
		}
		return $defn->{full};
	} else {
		return '';
	}
}

#
#	3.13	Operation Declaration
#

package Operation;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	my $type = $self->{type};
	$self->line_stamp($parser);
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{symbtab}->Insert($self);
	$parser->YYData->{unnamed_symbtab} = new UnnamedSymbtab($parser);
	TypeDeclarator->CheckDeprecated($parser, $type);
	TypeDeclarator->CheckForward($parser, $type);
	if (defined $parser->YYData->{curr_itf}) {
		$self->{itf} = $parser->YYData->{curr_itf}->{full};
		$parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full}
				unless($self->{idf} =~ /^_/);		# _get_ or _set_
	} else {
		$parser->Error(__PACKAGE__ . "::new ERROR_INTERNAL.\n");
	}
	unless (ref $type) {
		if ($type =~ /::([0-9A-Z_a-z]+)$/) {
			$parser->YYData->{unnamed_symbtab}->InsertUsed($1);
		}
	}
	$parser->YYData->{curr_node} = $self;
}

sub _CheckOneway {
	my $self = shift;
	my($parser) = @_;
	if (exists $self->{modifier} and $self->{modifier} eq 'oneway') {
		# 3.12.1	Operation Attribute
		my $type = $self->{type};
		unless (ref $type or $type->isa('VoidType')) {
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

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$self->line_stamp($parser);
	my $type = $self->{type};
	unless (ref $type) {
		if ($type =~ /::([0-9A-Z_a-z]+)$/) {
			$parser->YYData->{unnamed_symbtab}->InsertUsed($1);
		}
	}
	TypeDeclarator->CheckDeprecated($parser, $type);
	TypeDeclarator->CheckForward($parser, $type);
	$parser->YYData->{unnamed_symbtab}->Insert($self->{idf});
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{curr_node} = $self;
}

package VoidType;

use base qw(node);

#
#	3.14	Attribute Declaration
#

package Attributes;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	my @list;
	foreach (@{$self->{list_expr}}) {
		my $attr = new Attribute($parser,
				modifier			=>	$self->{modifier},
				type				=>	$self->{type},
				idf					=>	$_,
				list_getraise		=>	$self->{list_getraise},
				list_setraise		=>	$self->{list_setraise}
		);
		push @list, $attr->{full};
	}
	$self->configure(list_decl	=>	\@list);
}

package Attribute;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	return unless ($self->{idf});
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$self->line_stamp($parser);
	$parser->YYData->{symbtab}->Insert($self);
	if (defined $parser->YYData->{curr_itf}) {
		$self->{itf} = $parser->YYData->{curr_itf}->{full};
		$parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full};
	} else {
		$parser->Error(__PACKAGE__ . "::new ERROR_INTERNAL.\n");
	}
	$parser->YYData->{curr_node} = $self;
	my $op = new Operation($parser,
			type				=>	$self->{type},
			idf					=>	'_get_' . $self->{idf}
	);
	$op->Configure($parser,
			list_param		=>	[],
			list_raise		=>	$self->{list_getraise}
	);
	$self->configure(
			_get		=>	$op
	);
	unless (exists $self->{modifier}) {		# readonly
		$op = new Operation($parser,
				type			=>	new VoidType($parser,
											value		=>	'void'
									),
				idf				=>	'_set_' . $self->{idf}
		);
		# unnamed_symbtab created
		$op->Configure($parser,
				list_param		=>	[
										new Parameter($parser,
												attr	=>	'in',
												type	=>	$self->{type},
												idf		=>	'new' . ucfirst $self->{idf}
										)
									],
				list_raise		=>	$self->{list_setraise}
		);
		$self->configure(
				_set		=>	$op
		);
	}
}

#
#	3.15	Repository Identity Related Declarations
#

package TypeId;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	my $node = $parser->YYData->{symbtab}->Lookup($self->{idf});
	if (defined $node) {
		if (       $node->isa('Modules')
				or $node->isa('BaseInterface')
				or $node->isa('ForwardBaseInterface')
				or $node->isa('StateMember')
				or $node->isa('Constant')
				or $node->isa('TypeDeclarator')
				or $node->isa('Enum')
				or $node->isa('Exception')
				or $node->isa('Operation')
				or $node->isa('Attribute')
				or $node->isa('Provides')
				or $node->isa('Uses')
				or $node->isa('Emits')
				or $node->isa('Publishes')
				or $node->isa('Consumes')
				or $node->isa('Factory')
				or $node->isa('Finder') ) {
			if (exists $node->{id}) {
				$parser->Warning("TypeId/pragma conflict for '$self->{idf}'.\n");
			}
			if (exists $node->{typeid}) {
				$parser->Error("TypeId redefinition for '$self->{idf}'.\n");
			} else {
				$parser->YYData->{symbtab}->CheckID($node, $self->{value});
				$node->{typeid} = $self->{value};
			}
		} else {
			$parser->Error("Typeid not allowed for '$self->{idf}'.\n");
		}
	}
}

package TypePrefix;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	unless ($self->{value} =~ /^[0-9A-Za-z_:\.\/\-]*$/) {
		$parser->Warning("Invalid TypePrefix format for \"$self->{value}\".\n");
	}
	if ($self->{idf}) {
		my $node = $parser->YYData->{symbtab}->Lookup($self->{idf});
		if (defined $node) {
			if (       $node->isa('Modules')
					or $node->isa('Interface')
					or $node->isa('ForwardInterface')
					or $node->isa('Value')
					or $node->isa('ForwardValue')
					or $node->isa('Specification') ) {
				if ($node->{prefix}) {
					$parser->Warning("TypePrefix/pragma conflict for '$self->{idf}'.\n");
				}
				$node->{typeprefix} = $self->{value};
				$node->{_typeprefix} = $self->{value};
				$parser->YYData->{symbtab}->{typeprefix}->{$node->{full}} = $self->{value} . '/' . $node->{idf};
			} else {
				$parser->Error("Typeprefix not allowed for '$self->{idf}'.\n");
			}
		}
	} else {
		$parser->YYData->{symbtab}->{typeprefix}->{''} = $self->{value};
	}
}

#
#	3.16	Event Declaration
#

package Event;

use base qw(Value);

package RegularEvent;

use base qw(Event);

sub _CheckInheritance {
	my $self = shift;
	my($parser) = @_;
	if (exists $self->{inheritance}) {
		if (    exists $self->{inheritance}->{modifier}		# truncatable
			and exists $self->{modifier} ) {				# custom
			$parser->Error("'truncatable' is used in a custom event.\n");
		}
	}
}

sub _CheckLocal {
	# A local type may be used as a parameter, attribute, return type, or exception
	# declaration of a local interface or of a valuetype.
}

package AbstractEvent;

use base qw(Event);

sub _CheckInheritance {
	# empty
}

sub _CheckLocal {
	# A local type may be used as a parameter, attribute, return type, or exception
	# declaration of a local interface or of a valuetype.
}

package ForwardEvent;

use base qw(ForwardValue);

package ForwardRegularEvent;

use base qw(ForwardEvent);

package ForwardAbstractEvent;

use base qw(ForwardEvent);

#
#	3.17	Component Declaration
#

package Component;

use base qw(BaseInterface);

sub _CheckInheritance {
}

package ForwardComponent;

use base qw(ForwardBaseInterface);

package Provides;

use base qw(node);

package Uses;

use base qw(node);

package Emits;

use base qw(node);

package Publishes;

use base qw(node);

package Consumes;

use base qw(node);

#
#	3.18	Home Declaration
#

package Home;

use base qw(BaseInterface);

sub _CheckInheritance {
}

package Factory;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$parser->YYData->{symbtab}->Insert($self);
	$parser->YYData->{unnamed_symbtab} = new UnnamedSymbtab($parser);
	if (defined $parser->YYData->{curr_itf}) {
		$self->{itf} = $parser->YYData->{curr_itf}->{full};
		$parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full}
	} else {
		$parser->Error(__PACKAGE__ . "::new ERROR_INTERNAL.\n");
	}
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{curr_node} = $self;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my @list_in = ();
	foreach ( @{$self->{list_param}} ) {
		if      ($_->{attr} eq 'in') {
			unshift @list_in, $_;
		}
	}
	$self->{list_in} = \@list_in;
	$self->{list_inout} = [];
	$self->{list_out} = [];
	return $self;
}

package Finder;

use base qw(node);

sub _Init {
	my $self = shift;
	my ($parser) = @_;
	$parser->YYData->{symbtab}->Insert($self);
	$parser->YYData->{unnamed_symbtab} = new UnnamedSymbtab($parser);
	if (defined $parser->YYData->{curr_itf}) {
		$self->{itf} = $parser->YYData->{curr_itf}->{full};
		$parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full}
	} else {
		$parser->Error(__PACKAGE__,"::new ERROR_INTERNAL.\n");
	}
	if ($parser->YYData->{doc} ne '') {
		$self->{doc} = $parser->YYData->{doc};
		$parser->YYData->{doc} = '';
	}
	$parser->YYData->{curr_node} = $self;
}

sub Configure {
	my $self = shift;
	my $parser = shift;
	$self->configure(@_);
	my @list_in = ();
	foreach ( @{$self->{list_param}} ) {
		if      ($_->{attr} eq 'in') {
			unshift @list_in, $_;
		}
	}
	$self->{list_in} = \@list_in;
	$self->{list_inout} = [];
	$self->{list_out} = [];
	return $self;
}

=for tree

	node
		Specification -
		Import -
		Modules - NEW
		Module
		(BaseInterface) -
			(Interface)
				RegularInterface
				LocalInterface
				AbstractInterface
			(Value)
				RegularValue
				BoxedValue
				AbstractValue
				(Event) -
					RegularEvent
					AbstractEvent
			Component
			Home
		(ForwardBaseInterface)
			(ForwardInterface) -
				ForwardRegularInterface
				ForwardLocalInterface
				ForwardAbstractInterface
			(ForwardValue) -
				ForwardRegularValue -
				ForwardAbstractValue -
				(ForwardEvent) -
					ForwardRegularEvent -
					ForwardAbstractEvent -
			ForwardComponent -
		InheritanceSpec
		StateMembers
		StateMember
		Initializer
		Expression
		Constant
		UnaryOp -
		BinaryOp -
		(Literal)
			IntegerLiteral -
			StringLiteral -
			WideStringLiteral -
			CharacterLiteral -
			WideCharacterLiteral -
			FixedPtLiteral -
			FloatingLiteral -
			BooleanLiteral -
		TypeDeclarator
		TypeDeclarators
		(BasicType)
			FloatingPtType -
			IntegerType -
			CharType -
			WideCharType -
			BooleanType -
			OctetType -
			AnyType -
			ObjectType -
			ValueBaseType -
		(_ConstructedType)
			StructType
			UnionType
			EnumType
		(_ForwardConstructedType)
			ForwardStructType -
			ForwardUnionType -
		Members
		Array
		Single
		Case -
		Default -
		Element
		Enum
		(_TemplateType) -
			SequenceType
			StringType -
			WideStringType -
			FixedPtType
			FixedPtConstType - NEW
		Exception
		Operation
		Parameter
		VoidType -
		Attributes
		Attribute
		TypeId
		TypePrefix
		Provides
		Uses
		Emits
		Publishes
		Consumes
		Factory
		Finder

=end tree

1;

