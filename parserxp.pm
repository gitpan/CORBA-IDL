####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.05';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------




sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'' => -3,
			'NATIVE' => -392,
			'ABSTRACT' => -392,
			'STRUCT' => -392,
			'TYPEID' => 26,
			'IMPORT' => 27,
			'DECLSPEC' => 7,
			'TYPEPREFIX' => 28,
			'VALUETYPE' => -392,
			'TYPEDEF' => -392,
			'IDENTIFIER' => 30,
			'MODULE' => -392,
			'UNION' => -392,
			"[" => -392,
			'error' => 17,
			'CODE_FRAGMENT' => -392,
			'LOCAL' => -392,
			'CONST' => -392,
			'CUSTOM' => -392,
			'EXCEPTION' => -392,
			'ENUM' => -392,
			'INTERFACE' => -392
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 23,
			'imports' => 22,
			'interface_header' => 24,
			'except_dcl' => 2,
			'value_header' => 25,
			'specification' => 3,
			'module_header' => 4,
			'interface' => 5,
			'value_box_dcl' => 6,
			'value_abs_header' => 8,
			'type_id_dcl' => 9,
			'value_dcl' => 10,
			'import' => 11,
			'exception_header' => 29,
			'interface_dcl' => 12,
			'declspec' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'forward_dcl' => 16,
			'module' => 31,
			'type_prefix_dcl' => 18,
			'code_frag' => 20,
			'value_abs_dcl' => 19,
			'type_dcl' => 32,
			'definitions' => 21,
			'definition' => 33
		}
	},
	{#State 1
		DEFAULT => -68
	},
	{#State 2
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 36
		}
	},
	{#State 3
		ACTIONS => {
			'' => 37
		}
	},
	{#State 4
		ACTIONS => {
			"{" => 39,
			'error' => 38
		}
	},
	{#State 5
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 40
		}
	},
	{#State 6
		DEFAULT => -67
	},
	{#State 7
		DEFAULT => -393
	},
	{#State 8
		ACTIONS => {
			"{" => 41
		}
	},
	{#State 9
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 42
		}
	},
	{#State 10
		DEFAULT => -65
	},
	{#State 11
		ACTIONS => {
			'IMPORT' => 27
		},
		DEFAULT => -5,
		GOTOS => {
			'import' => 11,
			'imports' => 43
		}
	},
	{#State 12
		DEFAULT => -28
	},
	{#State 13
		ACTIONS => {
			'MODULE' => 47,
			"[" => 48,
			'CODE_FRAGMENT' => 50,
			'CONST' => 53,
			'EXCEPTION' => 55
		},
		DEFAULT => -394,
		GOTOS => {
			'struct_type' => 56,
			'type_dcl_def' => 45,
			'union_type' => 57,
			'struct_header' => 46,
			'enum_type' => 49,
			'props' => 44,
			'enum_header' => 51,
			'constr_forward_decl' => 52,
			'union_header' => 54
		}
	},
	{#State 14
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 58
		}
	},
	{#State 15
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 90,
			'SEQUENCE' => 63,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'WCHAR' => 76,
			"[" => 48,
			'OCTET' => 81,
			'FLOAT' => 83,
			'ANY' => 85
		},
		DEFAULT => -394,
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'props' => 67,
			'octet_type' => 68,
			'scoped_name' => 69,
			'wide_char_type' => 70,
			'type_spec' => 72,
			'signed_long_int' => 71,
			'string_type' => 74,
			'struct_header' => 46,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'base_type_spec' => 79,
			'enum_type' => 80,
			'enum_header' => 51,
			'union_header' => 54,
			'unsigned_short_int' => 82,
			'signed_longlong_int' => 84,
			'wide_string_type' => 89,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 97,
			'struct_type' => 99,
			'union_type' => 101,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 16
		DEFAULT => -29
	},
	{#State 17
		DEFAULT => -4
	},
	{#State 18
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 109
		}
	},
	{#State 19
		DEFAULT => -66
	},
	{#State 20
		DEFAULT => -18
	},
	{#State 21
		DEFAULT => -1
	},
	{#State 22
		ACTIONS => {
			'TYPEID' => 26,
			'DECLSPEC' => 7,
			'TYPEPREFIX' => 28,
			'IDENTIFIER' => 30
		},
		DEFAULT => -392,
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 23,
			'interface_header' => 24,
			'except_dcl' => 2,
			'value_header' => 25,
			'module_header' => 4,
			'interface' => 5,
			'value_box_dcl' => 6,
			'value_abs_header' => 8,
			'type_id_dcl' => 9,
			'value_dcl' => 10,
			'exception_header' => 29,
			'interface_dcl' => 12,
			'declspec' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'forward_dcl' => 16,
			'module' => 31,
			'type_prefix_dcl' => 18,
			'value_abs_dcl' => 19,
			'code_frag' => 20,
			'type_dcl' => 32,
			'definitions' => 110,
			'definition' => 33
		}
	},
	{#State 23
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 111
		}
	},
	{#State 24
		ACTIONS => {
			"{" => 112
		}
	},
	{#State 25
		ACTIONS => {
			"{" => 113
		}
	},
	{#State 26
		ACTIONS => {
			'error' => 115,
			'IDENTIFIER' => 102,
			"::" => 96
		},
		GOTOS => {
			'scoped_name' => 114
		}
	},
	{#State 27
		ACTIONS => {
			'error' => 117,
			'IDENTIFIER' => 102,
			"::" => 96,
			'STRING_LITERAL' => 119
		},
		GOTOS => {
			'string_literal' => 118,
			'scoped_name' => 116,
			'imported_scope' => 120
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 122,
			'IDENTIFIER' => 102,
			"::" => 123
		},
		GOTOS => {
			'scoped_name' => 121
		}
	},
	{#State 29
		ACTIONS => {
			"{" => 125,
			'error' => 124
		}
	},
	{#State 30
		ACTIONS => {
			'error' => 126
		}
	},
	{#State 31
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 127
		}
	},
	{#State 32
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 128
		}
	},
	{#State 33
		ACTIONS => {
			'' => -7,
			'TYPEID' => 26,
			'IMPORT' => 27,
			'DECLSPEC' => 7,
			'TYPEPREFIX' => 28,
			'IDENTIFIER' => 30,
			"}" => -7
		},
		DEFAULT => -392,
		GOTOS => {
			'value_forward_dcl' => 1,
			'imports' => 130,
			'const_dcl' => 23,
			'interface_header' => 24,
			'except_dcl' => 2,
			'value_header' => 25,
			'module_header' => 4,
			'interface' => 5,
			'value_box_dcl' => 6,
			'value_abs_header' => 8,
			'type_id_dcl' => 9,
			'value_dcl' => 10,
			'import' => 11,
			'exception_header' => 29,
			'interface_dcl' => 12,
			'declspec' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'forward_dcl' => 16,
			'module' => 31,
			'type_prefix_dcl' => 18,
			'code_frag' => 20,
			'value_abs_dcl' => 19,
			'type_dcl' => 32,
			'definitions' => 129,
			'definition' => 33
		}
	},
	{#State 34
		DEFAULT => -20
	},
	{#State 35
		DEFAULT => -21
	},
	{#State 36
		DEFAULT => -12
	},
	{#State 37
		DEFAULT => 0
	},
	{#State 38
		ACTIONS => {
			"}" => 131
		}
	},
	{#State 39
		ACTIONS => {
			'NATIVE' => -392,
			'ABSTRACT' => -392,
			'STRUCT' => -392,
			'TYPEID' => 26,
			'DECLSPEC' => 7,
			'TYPEPREFIX' => 28,
			'VALUETYPE' => -392,
			'TYPEDEF' => -392,
			'IDENTIFIER' => 30,
			'MODULE' => -392,
			'UNION' => -392,
			"[" => -392,
			'error' => 132,
			'CODE_FRAGMENT' => -392,
			'LOCAL' => -392,
			'CONST' => -392,
			'CUSTOM' => -392,
			'EXCEPTION' => -392,
			"}" => 133,
			'ENUM' => -392,
			'INTERFACE' => -392
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 23,
			'interface_header' => 24,
			'except_dcl' => 2,
			'value_header' => 25,
			'module_header' => 4,
			'interface' => 5,
			'value_box_dcl' => 6,
			'value_abs_header' => 8,
			'type_id_dcl' => 9,
			'value_dcl' => 10,
			'exception_header' => 29,
			'interface_dcl' => 12,
			'declspec' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'forward_dcl' => 16,
			'module' => 31,
			'type_prefix_dcl' => 18,
			'value_abs_dcl' => 19,
			'code_frag' => 20,
			'type_dcl' => 32,
			'definitions' => 134,
			'definition' => 33
		}
	},
	{#State 40
		DEFAULT => -13
	},
	{#State 41
		ACTIONS => {
			'PRIVATE' => -392,
			'ONEWAY' => -392,
			'FIXED' => -392,
			'SEQUENCE' => -392,
			'FACTORY' => -392,
			'DECLSPEC' => 7,
			'UNSIGNED' => -392,
			'SHORT' => -392,
			'WCHAR' => -392,
			"[" => -392,
			'CODE_FRAGMENT' => -392,
			'error' => 143,
			'CONST' => -392,
			'EXCEPTION' => -392,
			"}" => 146,
			'FLOAT' => -392,
			'OCTET' => -392,
			'ENUM' => -392,
			'ANY' => -392,
			'CHAR' => -392,
			'OBJECT' => -392,
			'VALUEBASE' => -392,
			'NATIVE' => -392,
			'VOID' => -392,
			'STRUCT' => -392,
			'DOUBLE' => -392,
			'TYPEID' => 26,
			'LONG' => -392,
			'STRING' => -392,
			"::" => -392,
			'TYPEPREFIX' => 28,
			'WSTRING' => -392,
			'TYPEDEF' => -392,
			'BOOLEAN' => -392,
			'IDENTIFIER' => -392,
			'UNION' => -392,
			'READONLY' => -392,
			'ATTRIBUTE' => -392,
			'PUBLIC' => -392
		},
		GOTOS => {
			'init_header_param' => 135,
			'const_dcl' => 147,
			'state_member' => 138,
			'except_dcl' => 137,
			'attr_spec' => 136,
			'readonly_attr_spec' => 139,
			'exports' => 148,
			'_export' => 149,
			'type_id_dcl' => 140,
			'export' => 150,
			'init_header' => 141,
			'op_header' => 151,
			'exception_header' => 29,
			'declspec' => 142,
			'op_dcl' => 152,
			'init_dcl' => 153,
			'type_prefix_dcl' => 144,
			'attr_dcl' => 154,
			'code_frag' => 145,
			'type_dcl' => 155
		}
	},
	{#State 42
		DEFAULT => -16
	},
	{#State 43
		DEFAULT => -6
	},
	{#State 44
		ACTIONS => {
			'TYPEDEF' => 163,
			'NATIVE' => 161,
			'ABSTRACT' => 156,
			'UNION' => 164,
			'STRUCT' => 162,
			'LOCAL' => 157,
			'CUSTOM' => 165,
			'VALUETYPE' => -87,
			'ENUM' => 159
		},
		DEFAULT => -37,
		GOTOS => {
			'value_mod' => 158,
			'interface_mod' => 160
		}
	},
	{#State 45
		DEFAULT => -175
	},
	{#State 46
		ACTIONS => {
			"{" => 166
		}
	},
	{#State 47
		ACTIONS => {
			'error' => 167,
			'IDENTIFIER' => 168
		}
	},
	{#State 48
		DEFAULT => -395,
		GOTOS => {
			'@2-1' => 169
		}
	},
	{#State 49
		DEFAULT => -179
	},
	{#State 50
		DEFAULT => -391
	},
	{#State 51
		ACTIONS => {
			"{" => 171,
			'error' => 170
		}
	},
	{#State 52
		DEFAULT => -183
	},
	{#State 53
		ACTIONS => {
			'CHAR' => 86,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'FIXED' => 173,
			'WCHAR' => 76,
			'DOUBLE' => 93,
			'error' => 179,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'OCTET' => 81,
			'FLOAT' => 83,
			'WSTRING' => 98,
			'UNSIGNED' => 73
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 172,
			'signed_int' => 62,
			'wide_string_type' => 180,
			'integer_type' => 182,
			'boolean_type' => 181,
			'char_type' => 174,
			'octet_type' => 175,
			'scoped_name' => 176,
			'fixed_pt_const_type' => 183,
			'wide_char_type' => 177,
			'signed_long_int' => 71,
			'signed_short_int' => 97,
			'const_type' => 184,
			'string_type' => 178,
			'unsigned_longlong_int' => 77,
			'unsigned_long_int' => 104,
			'unsigned_short_int' => 82,
			'signed_longlong_int' => 84
		}
	},
	{#State 54
		ACTIONS => {
			'SWITCH' => 185
		}
	},
	{#State 55
		ACTIONS => {
			'error' => 186,
			'IDENTIFIER' => 187
		}
	},
	{#State 56
		DEFAULT => -177
	},
	{#State 57
		DEFAULT => -178
	},
	{#State 58
		DEFAULT => -15
	},
	{#State 59
		DEFAULT => -220
	},
	{#State 60
		DEFAULT => -192
	},
	{#State 61
		ACTIONS => {
			"<" => 189,
			'error' => 188
		}
	},
	{#State 62
		DEFAULT => -219
	},
	{#State 63
		ACTIONS => {
			"<" => 191,
			'error' => 190
		}
	},
	{#State 64
		DEFAULT => -200
	},
	{#State 65
		DEFAULT => -194
	},
	{#State 66
		DEFAULT => -199
	},
	{#State 67
		ACTIONS => {
			'UNION' => 193,
			'STRUCT' => 192,
			'ENUM' => 159
		}
	},
	{#State 68
		DEFAULT => -197
	},
	{#State 69
		ACTIONS => {
			"::" => 194
		},
		DEFAULT => -190
	},
	{#State 70
		DEFAULT => -195
	},
	{#State 71
		DEFAULT => -222
	},
	{#State 72
		DEFAULT => -71
	},
	{#State 73
		ACTIONS => {
			'SHORT' => 195,
			'LONG' => 196
		}
	},
	{#State 74
		DEFAULT => -202
	},
	{#State 75
		DEFAULT => -224
	},
	{#State 76
		DEFAULT => -234
	},
	{#State 77
		DEFAULT => -229
	},
	{#State 78
		DEFAULT => -198
	},
	{#State 79
		DEFAULT => -188
	},
	{#State 80
		DEFAULT => -207
	},
	{#State 81
		DEFAULT => -236
	},
	{#State 82
		DEFAULT => -227
	},
	{#State 83
		DEFAULT => -216
	},
	{#State 84
		DEFAULT => -223
	},
	{#State 85
		DEFAULT => -237
	},
	{#State 86
		DEFAULT => -233
	},
	{#State 87
		DEFAULT => -238
	},
	{#State 88
		DEFAULT => -354
	},
	{#State 89
		DEFAULT => -203
	},
	{#State 90
		DEFAULT => -191
	},
	{#State 91
		DEFAULT => -196
	},
	{#State 92
		DEFAULT => -193
	},
	{#State 93
		DEFAULT => -217
	},
	{#State 94
		ACTIONS => {
			'DOUBLE' => 197,
			'LONG' => 198
		},
		DEFAULT => -225
	},
	{#State 95
		ACTIONS => {
			"<" => 199
		},
		DEFAULT => -285
	},
	{#State 96
		ACTIONS => {
			'error' => 200,
			'IDENTIFIER' => 201
		}
	},
	{#State 97
		DEFAULT => -221
	},
	{#State 98
		ACTIONS => {
			"<" => 202
		},
		DEFAULT => -288
	},
	{#State 99
		DEFAULT => -205
	},
	{#State 100
		DEFAULT => -235
	},
	{#State 101
		DEFAULT => -206
	},
	{#State 102
		DEFAULT => -60
	},
	{#State 103
		DEFAULT => -201
	},
	{#State 104
		DEFAULT => -228
	},
	{#State 105
		DEFAULT => -189
	},
	{#State 106
		DEFAULT => -187
	},
	{#State 107
		DEFAULT => -186
	},
	{#State 108
		DEFAULT => -204
	},
	{#State 109
		DEFAULT => -17
	},
	{#State 110
		DEFAULT => -2
	},
	{#State 111
		DEFAULT => -11
	},
	{#State 112
		ACTIONS => {
			'PRIVATE' => -392,
			'ONEWAY' => -392,
			'FIXED' => -392,
			'SEQUENCE' => -392,
			'FACTORY' => -392,
			'DECLSPEC' => 7,
			'UNSIGNED' => -392,
			'SHORT' => -392,
			'WCHAR' => -392,
			"[" => -392,
			'CODE_FRAGMENT' => -392,
			'error' => 203,
			'CONST' => -392,
			'EXCEPTION' => -392,
			"}" => 204,
			'FLOAT' => -392,
			'OCTET' => -392,
			'ENUM' => -392,
			'ANY' => -392,
			'CHAR' => -392,
			'OBJECT' => -392,
			'VALUEBASE' => -392,
			'NATIVE' => -392,
			'VOID' => -392,
			'STRUCT' => -392,
			'DOUBLE' => -392,
			'TYPEID' => 26,
			'LONG' => -392,
			'STRING' => -392,
			"::" => -392,
			'TYPEPREFIX' => 28,
			'WSTRING' => -392,
			'TYPEDEF' => -392,
			'BOOLEAN' => -392,
			'IDENTIFIER' => -392,
			'UNION' => -392,
			'READONLY' => -392,
			'ATTRIBUTE' => -392,
			'PUBLIC' => -392
		},
		GOTOS => {
			'init_header_param' => 135,
			'const_dcl' => 147,
			'state_member' => 138,
			'except_dcl' => 137,
			'attr_spec' => 136,
			'readonly_attr_spec' => 139,
			'exports' => 205,
			'_export' => 149,
			'type_id_dcl' => 140,
			'export' => 150,
			'init_header' => 141,
			'op_header' => 151,
			'exception_header' => 29,
			'declspec' => 142,
			'op_dcl' => 152,
			'init_dcl' => 153,
			'type_prefix_dcl' => 144,
			'attr_dcl' => 154,
			'code_frag' => 145,
			'type_dcl' => 155,
			'interface_body' => 206
		}
	},
	{#State 113
		ACTIONS => {
			'PRIVATE' => -392,
			'ONEWAY' => -392,
			'FIXED' => -392,
			'SEQUENCE' => -392,
			'FACTORY' => -392,
			'DECLSPEC' => 7,
			'UNSIGNED' => -392,
			'SHORT' => -392,
			'WCHAR' => -392,
			"[" => -392,
			'CODE_FRAGMENT' => -392,
			'error' => 209,
			'CONST' => -392,
			'EXCEPTION' => -392,
			"}" => 210,
			'FLOAT' => -392,
			'OCTET' => -392,
			'ENUM' => -392,
			'ANY' => -392,
			'CHAR' => -392,
			'OBJECT' => -392,
			'VALUEBASE' => -392,
			'NATIVE' => -392,
			'VOID' => -392,
			'STRUCT' => -392,
			'DOUBLE' => -392,
			'TYPEID' => 26,
			'LONG' => -392,
			'STRING' => -392,
			"::" => -392,
			'TYPEPREFIX' => 28,
			'WSTRING' => -392,
			'TYPEDEF' => -392,
			'BOOLEAN' => -392,
			'IDENTIFIER' => -392,
			'UNION' => -392,
			'READONLY' => -392,
			'ATTRIBUTE' => -392,
			'PUBLIC' => -392
		},
		GOTOS => {
			'init_header_param' => 135,
			'const_dcl' => 147,
			'value_elements' => 211,
			'except_dcl' => 137,
			'state_member' => 207,
			'attr_spec' => 136,
			'value_element' => 208,
			'readonly_attr_spec' => 139,
			'type_id_dcl' => 140,
			'export' => 212,
			'init_header' => 141,
			'op_header' => 151,
			'exception_header' => 29,
			'declspec' => 142,
			'op_dcl' => 152,
			'init_dcl' => 213,
			'type_prefix_dcl' => 144,
			'attr_dcl' => 154,
			'code_frag' => 145,
			'type_dcl' => 155
		}
	},
	{#State 114
		ACTIONS => {
			'error' => 214,
			"::" => 194,
			'STRING_LITERAL' => 119
		},
		GOTOS => {
			'string_literal' => 215
		}
	},
	{#State 115
		DEFAULT => -365
	},
	{#State 116
		ACTIONS => {
			"::" => 194
		},
		DEFAULT => -361
	},
	{#State 117
		DEFAULT => -360
	},
	{#State 118
		DEFAULT => -362
	},
	{#State 119
		ACTIONS => {
			'STRING_LITERAL' => 119
		},
		DEFAULT => -168,
		GOTOS => {
			'string_literal' => 216
		}
	},
	{#State 120
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 217
		}
	},
	{#State 121
		ACTIONS => {
			'error' => 218,
			"::" => 194,
			'STRING_LITERAL' => 119
		},
		GOTOS => {
			'string_literal' => 219
		}
	},
	{#State 122
		DEFAULT => -369
	},
	{#State 123
		ACTIONS => {
			'error' => 200,
			'IDENTIFIER' => 201,
			'STRING_LITERAL' => 119
		},
		GOTOS => {
			'string_literal' => 220
		}
	},
	{#State 124
		DEFAULT => -300
	},
	{#State 125
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 90,
			'SEQUENCE' => 63,
			'STRUCT' => -394,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'UNION' => -394,
			'WCHAR' => 76,
			"[" => 48,
			'error' => 222,
			'OCTET' => 81,
			'FLOAT' => 83,
			"}" => 224,
			'ENUM' => -394,
			'ANY' => 85
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'props' => 67,
			'octet_type' => 68,
			'scoped_name' => 69,
			'wide_char_type' => 70,
			'signed_long_int' => 71,
			'type_spec' => 221,
			'string_type' => 74,
			'struct_header' => 46,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'base_type_spec' => 79,
			'enum_type' => 80,
			'enum_header' => 51,
			'member_list' => 223,
			'union_header' => 54,
			'unsigned_short_int' => 82,
			'signed_longlong_int' => 84,
			'wide_string_type' => 89,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 97,
			'member' => 225,
			'struct_type' => 99,
			'union_type' => 101,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 126
		ACTIONS => {
			";" => 226
		}
	},
	{#State 127
		DEFAULT => -14
	},
	{#State 128
		DEFAULT => -10
	},
	{#State 129
		DEFAULT => -8
	},
	{#State 130
		ACTIONS => {
			'TYPEID' => 26,
			'DECLSPEC' => 7,
			'TYPEPREFIX' => 28,
			'IDENTIFIER' => 30
		},
		DEFAULT => -392,
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 23,
			'interface_header' => 24,
			'except_dcl' => 2,
			'value_header' => 25,
			'module_header' => 4,
			'interface' => 5,
			'value_box_dcl' => 6,
			'value_abs_header' => 8,
			'type_id_dcl' => 9,
			'value_dcl' => 10,
			'exception_header' => 29,
			'interface_dcl' => 12,
			'declspec' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'forward_dcl' => 16,
			'module' => 31,
			'type_prefix_dcl' => 18,
			'value_abs_dcl' => 19,
			'code_frag' => 20,
			'type_dcl' => 32,
			'definitions' => 227,
			'definition' => 33
		}
	},
	{#State 131
		DEFAULT => -25
	},
	{#State 132
		ACTIONS => {
			"}" => 228
		}
	},
	{#State 133
		DEFAULT => -24
	},
	{#State 134
		ACTIONS => {
			"}" => 229
		}
	},
	{#State 135
		ACTIONS => {
			'RAISES' => 231
		},
		DEFAULT => -331,
		GOTOS => {
			'raises_expr' => 230
		}
	},
	{#State 136
		DEFAULT => -296
	},
	{#State 137
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 232
		}
	},
	{#State 138
		DEFAULT => -44
	},
	{#State 139
		DEFAULT => -295
	},
	{#State 140
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 233
		}
	},
	{#State 141
		ACTIONS => {
			'error' => 235,
			"(" => 234
		}
	},
	{#State 142
		ACTIONS => {
			"[" => 48,
			'CODE_FRAGMENT' => 50,
			'CONST' => 53,
			'EXCEPTION' => 55
		},
		DEFAULT => -394,
		GOTOS => {
			'struct_type' => 56,
			'type_dcl_def' => 45,
			'union_type' => 57,
			'struct_header' => 46,
			'enum_type' => 49,
			'props' => 236,
			'enum_header' => 51,
			'constr_forward_decl' => 52,
			'union_header' => 54
		}
	},
	{#State 143
		ACTIONS => {
			"}" => 237
		}
	},
	{#State 144
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 238
		}
	},
	{#State 145
		DEFAULT => -53
	},
	{#State 146
		DEFAULT => -73
	},
	{#State 147
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 239
		}
	},
	{#State 148
		ACTIONS => {
			"}" => 240
		}
	},
	{#State 149
		ACTIONS => {
			'DECLSPEC' => 7,
			"}" => -41,
			'TYPEID' => 26,
			'TYPEPREFIX' => 28
		},
		DEFAULT => -392,
		GOTOS => {
			'init_header_param' => 135,
			'const_dcl' => 147,
			'state_member' => 138,
			'except_dcl' => 137,
			'attr_spec' => 136,
			'readonly_attr_spec' => 139,
			'exports' => 241,
			'_export' => 149,
			'type_id_dcl' => 140,
			'export' => 150,
			'init_header' => 141,
			'op_header' => 151,
			'exception_header' => 29,
			'declspec' => 142,
			'op_dcl' => 152,
			'init_dcl' => 153,
			'type_prefix_dcl' => 144,
			'attr_dcl' => 154,
			'code_frag' => 145,
			'type_dcl' => 155
		}
	},
	{#State 150
		DEFAULT => -43
	},
	{#State 151
		ACTIONS => {
			'error' => 243,
			"(" => 242
		},
		GOTOS => {
			'parameter_dcls' => 244
		}
	},
	{#State 152
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 245
		}
	},
	{#State 153
		DEFAULT => -45
	},
	{#State 154
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 246
		}
	},
	{#State 155
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 247
		}
	},
	{#State 156
		ACTIONS => {
			'error' => 249,
			'VALUETYPE' => 248,
			'INTERFACE' => -35
		}
	},
	{#State 157
		DEFAULT => -36
	},
	{#State 158
		ACTIONS => {
			'VALUETYPE' => 250
		}
	},
	{#State 159
		ACTIONS => {
			'error' => 251,
			'IDENTIFIER' => 252
		}
	},
	{#State 160
		ACTIONS => {
			'INTERFACE' => 253
		}
	},
	{#State 161
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 256
		},
		GOTOS => {
			'simple_declarator' => 255
		}
	},
	{#State 162
		ACTIONS => {
			'error' => 257,
			'IDENTIFIER' => 258
		}
	},
	{#State 163
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 90,
			'SEQUENCE' => 63,
			'STRUCT' => -394,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'UNION' => -394,
			'WCHAR' => 76,
			"[" => 48,
			'error' => 261,
			'OCTET' => 81,
			'FLOAT' => 83,
			'ENUM' => -394,
			'ANY' => 85
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'props' => 67,
			'octet_type' => 68,
			'scoped_name' => 69,
			'wide_char_type' => 70,
			'type_spec' => 259,
			'signed_long_int' => 71,
			'type_declarator' => 260,
			'string_type' => 74,
			'struct_header' => 46,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'base_type_spec' => 79,
			'enum_type' => 80,
			'enum_header' => 51,
			'union_header' => 54,
			'unsigned_short_int' => 82,
			'signed_longlong_int' => 84,
			'wide_string_type' => 89,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 97,
			'struct_type' => 99,
			'union_type' => 101,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 164
		ACTIONS => {
			'error' => 262,
			'IDENTIFIER' => 263
		}
	},
	{#State 165
		DEFAULT => -86
	},
	{#State 166
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 90,
			'SEQUENCE' => 63,
			'STRUCT' => -394,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'UNION' => -394,
			'WCHAR' => 76,
			"[" => 48,
			'error' => 264,
			'OCTET' => 81,
			'FLOAT' => 83,
			'ENUM' => -394,
			'ANY' => 85
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'props' => 67,
			'octet_type' => 68,
			'scoped_name' => 69,
			'wide_char_type' => 70,
			'signed_long_int' => 71,
			'type_spec' => 221,
			'string_type' => 74,
			'struct_header' => 46,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'base_type_spec' => 79,
			'enum_type' => 80,
			'enum_header' => 51,
			'member_list' => 265,
			'union_header' => 54,
			'unsigned_short_int' => 82,
			'signed_longlong_int' => 84,
			'wide_string_type' => 89,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 97,
			'member' => 225,
			'struct_type' => 99,
			'union_type' => 101,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 167
		DEFAULT => -27
	},
	{#State 168
		DEFAULT => -26
	},
	{#State 169
		ACTIONS => {
			'PROP_KEY' => 267
		},
		GOTOS => {
			'prop_list' => 266
		}
	},
	{#State 170
		DEFAULT => -271
	},
	{#State 171
		ACTIONS => {
			'error' => 268,
			'IDENTIFIER' => 270
		},
		GOTOS => {
			'enumerators' => 271,
			'enumerator' => 269
		}
	},
	{#State 172
		DEFAULT => -128
	},
	{#State 173
		DEFAULT => -353
	},
	{#State 174
		DEFAULT => -125
	},
	{#State 175
		DEFAULT => -133
	},
	{#State 176
		ACTIONS => {
			"::" => 194
		},
		DEFAULT => -132
	},
	{#State 177
		DEFAULT => -126
	},
	{#State 178
		DEFAULT => -129
	},
	{#State 179
		DEFAULT => -123
	},
	{#State 180
		DEFAULT => -130
	},
	{#State 181
		DEFAULT => -127
	},
	{#State 182
		DEFAULT => -124
	},
	{#State 183
		DEFAULT => -131
	},
	{#State 184
		ACTIONS => {
			'error' => 272,
			'IDENTIFIER' => 273
		}
	},
	{#State 185
		ACTIONS => {
			'error' => 275,
			"(" => 274
		}
	},
	{#State 186
		DEFAULT => -302
	},
	{#State 187
		DEFAULT => -301
	},
	{#State 188
		DEFAULT => -352
	},
	{#State 189
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'CHARACTER_LITERAL' => 276,
			'WIDE_CHARACTER_LITERAL' => 277,
			"::" => 96,
			'INTEGER_LITERAL' => 297,
			"(" => 281,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'FIXED_PT_LITERAL' => 299,
			"+" => 300,
			'error' => 285,
			"-" => 302,
			'WIDE_STRING_LITERAL' => 289,
			'FALSE' => 288,
			"~" => 303,
			'TRUE' => 291
		},
		GOTOS => {
			'string_literal' => 293,
			'primary_expr' => 295,
			'and_expr' => 296,
			'scoped_name' => 278,
			'positive_int_const' => 279,
			'wide_string_literal' => 280,
			'boolean_literal' => 282,
			'mult_expr' => 298,
			'const_exp' => 283,
			'or_expr' => 284,
			'unary_expr' => 301,
			'xor_expr' => 286,
			'shift_expr' => 287,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 190
		DEFAULT => -283
	},
	{#State 191
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 90,
			'SEQUENCE' => 63,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'WCHAR' => 76,
			'error' => 305,
			'FLOAT' => 83,
			'OCTET' => 81,
			'ANY' => 85
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 89,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 68,
			'scoped_name' => 69,
			'wide_char_type' => 70,
			'signed_long_int' => 71,
			'signed_short_int' => 97,
			'string_type' => 74,
			'sequence_type' => 103,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'base_type_spec' => 79,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'unsigned_short_int' => 82,
			'simple_type_spec' => 306,
			'fixed_pt_type' => 108,
			'signed_longlong_int' => 84
		}
	},
	{#State 192
		ACTIONS => {
			'error' => 307,
			'IDENTIFIER' => 308
		}
	},
	{#State 193
		ACTIONS => {
			'error' => 309,
			'IDENTIFIER' => 310
		}
	},
	{#State 194
		ACTIONS => {
			'error' => 311,
			'IDENTIFIER' => 312
		}
	},
	{#State 195
		DEFAULT => -230
	},
	{#State 196
		ACTIONS => {
			'LONG' => 313
		},
		DEFAULT => -231
	},
	{#State 197
		DEFAULT => -218
	},
	{#State 198
		DEFAULT => -226
	},
	{#State 199
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'CHARACTER_LITERAL' => 276,
			'WIDE_CHARACTER_LITERAL' => 277,
			"::" => 96,
			'INTEGER_LITERAL' => 297,
			"(" => 281,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'FIXED_PT_LITERAL' => 299,
			"+" => 300,
			'error' => 315,
			"-" => 302,
			'WIDE_STRING_LITERAL' => 289,
			'FALSE' => 288,
			"~" => 303,
			'TRUE' => 291
		},
		GOTOS => {
			'string_literal' => 293,
			'primary_expr' => 295,
			'and_expr' => 296,
			'scoped_name' => 278,
			'positive_int_const' => 314,
			'wide_string_literal' => 280,
			'boolean_literal' => 282,
			'mult_expr' => 298,
			'const_exp' => 283,
			'or_expr' => 284,
			'unary_expr' => 301,
			'xor_expr' => 286,
			'shift_expr' => 287,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 200
		DEFAULT => -62
	},
	{#State 201
		DEFAULT => -61
	},
	{#State 202
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'CHARACTER_LITERAL' => 276,
			'WIDE_CHARACTER_LITERAL' => 277,
			"::" => 96,
			'INTEGER_LITERAL' => 297,
			"(" => 281,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'FIXED_PT_LITERAL' => 299,
			"+" => 300,
			'error' => 317,
			"-" => 302,
			'WIDE_STRING_LITERAL' => 289,
			'FALSE' => 288,
			"~" => 303,
			'TRUE' => 291
		},
		GOTOS => {
			'string_literal' => 293,
			'primary_expr' => 295,
			'and_expr' => 296,
			'scoped_name' => 278,
			'positive_int_const' => 316,
			'wide_string_literal' => 280,
			'boolean_literal' => 282,
			'mult_expr' => 298,
			'const_exp' => 283,
			'or_expr' => 284,
			'unary_expr' => 301,
			'xor_expr' => 286,
			'shift_expr' => 287,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 203
		ACTIONS => {
			"}" => 318
		}
	},
	{#State 204
		DEFAULT => -30
	},
	{#State 205
		DEFAULT => -40
	},
	{#State 206
		ACTIONS => {
			"}" => 319
		}
	},
	{#State 207
		DEFAULT => -100
	},
	{#State 208
		ACTIONS => {
			'DECLSPEC' => 7,
			"}" => -82,
			'TYPEID' => 26,
			'TYPEPREFIX' => 28
		},
		DEFAULT => -392,
		GOTOS => {
			'init_header_param' => 135,
			'const_dcl' => 147,
			'value_elements' => 320,
			'except_dcl' => 137,
			'state_member' => 207,
			'attr_spec' => 136,
			'value_element' => 208,
			'readonly_attr_spec' => 139,
			'type_id_dcl' => 140,
			'export' => 212,
			'init_header' => 141,
			'op_header' => 151,
			'exception_header' => 29,
			'declspec' => 142,
			'op_dcl' => 152,
			'init_dcl' => 213,
			'type_prefix_dcl' => 144,
			'attr_dcl' => 154,
			'code_frag' => 145,
			'type_dcl' => 155
		}
	},
	{#State 209
		ACTIONS => {
			"}" => 321
		}
	},
	{#State 210
		DEFAULT => -79
	},
	{#State 211
		ACTIONS => {
			"}" => 322
		}
	},
	{#State 212
		DEFAULT => -99
	},
	{#State 213
		DEFAULT => -101
	},
	{#State 214
		DEFAULT => -364
	},
	{#State 215
		DEFAULT => -363
	},
	{#State 216
		DEFAULT => -169
	},
	{#State 217
		DEFAULT => -359
	},
	{#State 218
		DEFAULT => -367
	},
	{#State 219
		DEFAULT => -366
	},
	{#State 220
		DEFAULT => -368
	},
	{#State 221
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 328
		},
		GOTOS => {
			'declarators' => 323,
			'declarator' => 324,
			'simple_declarator' => 326,
			'array_declarator' => 327,
			'complex_declarator' => 325
		}
	},
	{#State 222
		ACTIONS => {
			"}" => 329
		}
	},
	{#State 223
		ACTIONS => {
			"}" => 330
		}
	},
	{#State 224
		DEFAULT => -297
	},
	{#State 225
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 90,
			'SEQUENCE' => 63,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'WCHAR' => 76,
			"[" => 48,
			"}" => -243,
			'OCTET' => 81,
			'FLOAT' => 83,
			'ANY' => 85
		},
		DEFAULT => -394,
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'props' => 67,
			'octet_type' => 68,
			'scoped_name' => 69,
			'wide_char_type' => 70,
			'signed_long_int' => 71,
			'type_spec' => 221,
			'string_type' => 74,
			'struct_header' => 46,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'base_type_spec' => 79,
			'enum_type' => 80,
			'enum_header' => 51,
			'member_list' => 331,
			'union_header' => 54,
			'unsigned_short_int' => 82,
			'signed_longlong_int' => 84,
			'wide_string_type' => 89,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 97,
			'member' => 225,
			'struct_type' => 99,
			'union_type' => 101,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 226
		DEFAULT => -19
	},
	{#State 227
		DEFAULT => -9
	},
	{#State 228
		DEFAULT => -23
	},
	{#State 229
		DEFAULT => -22
	},
	{#State 230
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 332
		}
	},
	{#State 231
		ACTIONS => {
			'error' => 334,
			"(" => 333
		}
	},
	{#State 232
		DEFAULT => -48
	},
	{#State 233
		DEFAULT => -51
	},
	{#State 234
		ACTIONS => {
			'error' => 339,
			")" => 340,
			'IN' => 337
		},
		GOTOS => {
			'init_param_decls' => 336,
			'init_param_attribute' => 335,
			'init_param_decl' => 338
		}
	},
	{#State 235
		DEFAULT => -111
	},
	{#State 236
		ACTIONS => {
			'PRIVATE' => 341,
			'ONEWAY' => 342,
			'NATIVE' => 161,
			'STRUCT' => 162,
			'FACTORY' => 346,
			'TYPEDEF' => 163,
			'UNION' => 164,
			'READONLY' => 347,
			'PUBLIC' => 348,
			'ATTRIBUTE' => 349,
			'ENUM' => 159
		},
		DEFAULT => -308,
		GOTOS => {
			'op_mod' => 343,
			'op_attribute' => 344,
			'state_mod' => 345
		}
	},
	{#State 237
		DEFAULT => -75
	},
	{#State 238
		DEFAULT => -52
	},
	{#State 239
		DEFAULT => -47
	},
	{#State 240
		DEFAULT => -74
	},
	{#State 241
		DEFAULT => -42
	},
	{#State 242
		ACTIONS => {
			'CHAR' => -394,
			'OBJECT' => -394,
			'FIXED' => -394,
			'VALUEBASE' => -394,
			'VOID' => -394,
			'IN' => -394,
			'SEQUENCE' => -394,
			'DOUBLE' => -394,
			'LONG' => -394,
			'STRING' => -394,
			"::" => -394,
			'WSTRING' => -394,
			"..." => 351,
			'UNSIGNED' => -394,
			'SHORT' => -394,
			")" => 354,
			'OUT' => -394,
			'BOOLEAN' => -394,
			'IDENTIFIER' => -394,
			'WCHAR' => -394,
			"[" => 48,
			'error' => 352,
			'OCTET' => -394,
			'INOUT' => -394,
			'FLOAT' => -394,
			'ANY' => -394
		},
		GOTOS => {
			'props' => 350,
			'param_dcl' => 355,
			'param_dcls' => 353
		}
	},
	{#State 243
		DEFAULT => -304
	},
	{#State 244
		ACTIONS => {
			'RAISES' => 231
		},
		DEFAULT => -331,
		GOTOS => {
			'raises_expr' => 356
		}
	},
	{#State 245
		DEFAULT => -50
	},
	{#State 246
		DEFAULT => -49
	},
	{#State 247
		DEFAULT => -46
	},
	{#State 248
		ACTIONS => {
			'error' => 357,
			'IDENTIFIER' => 358
		}
	},
	{#State 249
		DEFAULT => -78
	},
	{#State 250
		ACTIONS => {
			'error' => 359,
			'IDENTIFIER' => 360
		}
	},
	{#State 251
		DEFAULT => -273
	},
	{#State 252
		DEFAULT => -272
	},
	{#State 253
		ACTIONS => {
			'error' => 361,
			'IDENTIFIER' => 362
		}
	},
	{#State 254
		ACTIONS => {
			";" => 363,
			"," => 364
		}
	},
	{#State 255
		ACTIONS => {
			"(" => 365
		},
		DEFAULT => -180
	},
	{#State 256
		DEFAULT => -212
	},
	{#State 257
		ACTIONS => {
			"{" => -242
		},
		DEFAULT => -356
	},
	{#State 258
		ACTIONS => {
			"{" => -241
		},
		DEFAULT => -355
	},
	{#State 259
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 328
		},
		GOTOS => {
			'declarators' => 366,
			'declarator' => 324,
			'simple_declarator' => 326,
			'array_declarator' => 327,
			'complex_declarator' => 325
		}
	},
	{#State 260
		DEFAULT => -176
	},
	{#State 261
		DEFAULT => -184
	},
	{#State 262
		ACTIONS => {
			'SWITCH' => -252
		},
		DEFAULT => -358
	},
	{#State 263
		ACTIONS => {
			'SWITCH' => -251
		},
		DEFAULT => -357
	},
	{#State 264
		ACTIONS => {
			"}" => 367
		}
	},
	{#State 265
		ACTIONS => {
			"}" => 368
		}
	},
	{#State 266
		ACTIONS => {
			"]" => 370,
			"," => 369
		}
	},
	{#State 267
		ACTIONS => {
			'PROP_VALUE' => 371
		},
		DEFAULT => -399
	},
	{#State 268
		ACTIONS => {
			"}" => 372
		}
	},
	{#State 269
		ACTIONS => {
			";" => 373,
			"," => 374
		},
		DEFAULT => -274
	},
	{#State 270
		DEFAULT => -278
	},
	{#State 271
		ACTIONS => {
			"}" => 375
		}
	},
	{#State 272
		DEFAULT => -122
	},
	{#State 273
		ACTIONS => {
			'error' => 376,
			"=" => 377
		}
	},
	{#State 274
		ACTIONS => {
			'CHAR' => 86,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			"[" => 48,
			'error' => 382,
			'LONG' => 386,
			"::" => 96,
			'ENUM' => -394,
			'UNSIGNED' => 73
		},
		GOTOS => {
			'switch_type_spec' => 383,
			'unsigned_int' => 59,
			'signed_int' => 62,
			'integer_type' => 385,
			'boolean_type' => 384,
			'char_type' => 378,
			'props' => 379,
			'scoped_name' => 380,
			'signed_long_int' => 71,
			'signed_short_int' => 97,
			'unsigned_longlong_int' => 77,
			'enum_type' => 381,
			'unsigned_long_int' => 104,
			'enum_header' => 51,
			'unsigned_short_int' => 82,
			'signed_longlong_int' => 84
		}
	},
	{#State 275
		DEFAULT => -250
	},
	{#State 276
		DEFAULT => -163
	},
	{#State 277
		DEFAULT => -164
	},
	{#State 278
		ACTIONS => {
			"::" => 194
		},
		DEFAULT => -156
	},
	{#State 279
		ACTIONS => {
			"," => 387
		}
	},
	{#State 280
		DEFAULT => -162
	},
	{#State 281
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'CHARACTER_LITERAL' => 276,
			'WIDE_CHARACTER_LITERAL' => 277,
			"::" => 96,
			'INTEGER_LITERAL' => 297,
			"(" => 281,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'FIXED_PT_LITERAL' => 299,
			"+" => 300,
			'error' => 389,
			"-" => 302,
			'WIDE_STRING_LITERAL' => 289,
			'FALSE' => 288,
			"~" => 303,
			'TRUE' => 291
		},
		GOTOS => {
			'mult_expr' => 298,
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'const_exp' => 388,
			'and_expr' => 296,
			'or_expr' => 284,
			'unary_expr' => 301,
			'scoped_name' => 278,
			'xor_expr' => 286,
			'shift_expr' => 287,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 282
		DEFAULT => -167
	},
	{#State 283
		DEFAULT => -174
	},
	{#State 284
		ACTIONS => {
			"|" => 390
		},
		DEFAULT => -134
	},
	{#State 285
		ACTIONS => {
			">" => 391
		}
	},
	{#State 286
		ACTIONS => {
			"^" => 392
		},
		DEFAULT => -135
	},
	{#State 287
		ACTIONS => {
			"<<" => 393,
			">>" => 394
		},
		DEFAULT => -139
	},
	{#State 288
		DEFAULT => -173
	},
	{#State 289
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 289
		},
		DEFAULT => -170,
		GOTOS => {
			'wide_string_literal' => 395
		}
	},
	{#State 290
		DEFAULT => -157
	},
	{#State 291
		DEFAULT => -172
	},
	{#State 292
		ACTIONS => {
			"+" => 396,
			"-" => 397
		},
		DEFAULT => -141
	},
	{#State 293
		DEFAULT => -161
	},
	{#State 294
		DEFAULT => -166
	},
	{#State 295
		DEFAULT => -152
	},
	{#State 296
		ACTIONS => {
			"&" => 398
		},
		DEFAULT => -137
	},
	{#State 297
		DEFAULT => -160
	},
	{#State 298
		ACTIONS => {
			"%" => 400,
			"*" => 399,
			"/" => 401
		},
		DEFAULT => -144
	},
	{#State 299
		DEFAULT => -165
	},
	{#State 300
		DEFAULT => -154
	},
	{#State 301
		DEFAULT => -147
	},
	{#State 302
		DEFAULT => -153
	},
	{#State 303
		DEFAULT => -155
	},
	{#State 304
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'string_literal' => 293,
			'boolean_literal' => 282,
			'scoped_name' => 278,
			'primary_expr' => 402,
			'literal' => 290,
			'wide_string_literal' => 280
		}
	},
	{#State 305
		ACTIONS => {
			">" => 403
		}
	},
	{#State 306
		ACTIONS => {
			">" => 405,
			"," => 404
		}
	},
	{#State 307
		DEFAULT => -242
	},
	{#State 308
		DEFAULT => -241
	},
	{#State 309
		DEFAULT => -252
	},
	{#State 310
		DEFAULT => -251
	},
	{#State 311
		DEFAULT => -64
	},
	{#State 312
		DEFAULT => -63
	},
	{#State 313
		DEFAULT => -232
	},
	{#State 314
		ACTIONS => {
			">" => 406
		}
	},
	{#State 315
		ACTIONS => {
			">" => 407
		}
	},
	{#State 316
		ACTIONS => {
			">" => 408
		}
	},
	{#State 317
		ACTIONS => {
			">" => 409
		}
	},
	{#State 318
		DEFAULT => -32
	},
	{#State 319
		DEFAULT => -31
	},
	{#State 320
		DEFAULT => -83
	},
	{#State 321
		DEFAULT => -81
	},
	{#State 322
		DEFAULT => -80
	},
	{#State 323
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 410
		}
	},
	{#State 324
		ACTIONS => {
			"," => 411
		},
		DEFAULT => -208
	},
	{#State 325
		DEFAULT => -211
	},
	{#State 326
		DEFAULT => -210
	},
	{#State 327
		DEFAULT => -215
	},
	{#State 328
		ACTIONS => {
			"[" => 414
		},
		DEFAULT => -212,
		GOTOS => {
			'fixed_array_sizes' => 412,
			'fixed_array_size' => 413
		}
	},
	{#State 329
		DEFAULT => -299
	},
	{#State 330
		DEFAULT => -298
	},
	{#State 331
		DEFAULT => -244
	},
	{#State 332
		DEFAULT => -107
	},
	{#State 333
		ACTIONS => {
			'error' => 416,
			'IDENTIFIER' => 102,
			"::" => 96
		},
		GOTOS => {
			'scoped_name' => 415,
			'exception_names' => 417,
			'exception_name' => 418
		}
	},
	{#State 334
		DEFAULT => -330
	},
	{#State 335
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 425,
			'SEQUENCE' => 63,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'WCHAR' => 76,
			'error' => 422,
			'FLOAT' => 83,
			'OCTET' => 81,
			'ANY' => 85
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 424,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 68,
			'scoped_name' => 419,
			'wide_char_type' => 70,
			'signed_long_int' => 71,
			'signed_short_int' => 97,
			'string_type' => 420,
			'op_param_type_spec' => 426,
			'sequence_type' => 427,
			'base_type_spec' => 421,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'unsigned_long_int' => 104,
			'param_type_spec' => 423,
			'unsigned_short_int' => 82,
			'fixed_pt_type' => 428,
			'signed_longlong_int' => 84
		}
	},
	{#State 336
		ACTIONS => {
			")" => 429
		}
	},
	{#State 337
		DEFAULT => -118
	},
	{#State 338
		ACTIONS => {
			"," => 430
		},
		DEFAULT => -114
	},
	{#State 339
		ACTIONS => {
			")" => 431
		}
	},
	{#State 340
		DEFAULT => -108
	},
	{#State 341
		DEFAULT => -106
	},
	{#State 342
		DEFAULT => -309
	},
	{#State 343
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 432,
			'SEQUENCE' => 63,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'WCHAR' => 76,
			'FLOAT' => 83,
			'OCTET' => 81,
			'ANY' => 85
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 424,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 68,
			'scoped_name' => 419,
			'wide_char_type' => 70,
			'signed_long_int' => 71,
			'signed_short_int' => 97,
			'string_type' => 420,
			'op_type_spec' => 434,
			'op_param_type_spec' => 433,
			'sequence_type' => 435,
			'base_type_spec' => 421,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'unsigned_long_int' => 104,
			'unsigned_short_int' => 82,
			'fixed_pt_type' => 436,
			'signed_longlong_int' => 84
		}
	},
	{#State 344
		DEFAULT => -307
	},
	{#State 345
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 90,
			'SEQUENCE' => 63,
			'STRUCT' => -394,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'UNION' => -394,
			'WCHAR' => 76,
			"[" => 48,
			'error' => 438,
			'OCTET' => 81,
			'FLOAT' => 83,
			'ENUM' => -394,
			'ANY' => 85
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'props' => 67,
			'octet_type' => 68,
			'scoped_name' => 69,
			'wide_char_type' => 70,
			'type_spec' => 437,
			'signed_long_int' => 71,
			'string_type' => 74,
			'struct_header' => 46,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'base_type_spec' => 79,
			'enum_type' => 80,
			'enum_header' => 51,
			'union_header' => 54,
			'unsigned_short_int' => 82,
			'signed_longlong_int' => 84,
			'wide_string_type' => 89,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 97,
			'struct_type' => 99,
			'union_type' => 101,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 346
		ACTIONS => {
			'error' => 439,
			'IDENTIFIER' => 440
		}
	},
	{#State 347
		ACTIONS => {
			'error' => 441,
			'ATTRIBUTE' => 442
		}
	},
	{#State 348
		DEFAULT => -105
	},
	{#State 349
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 425,
			'SEQUENCE' => 63,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'WCHAR' => 76,
			'error' => 443,
			'FLOAT' => 83,
			'OCTET' => 81,
			'ANY' => 85
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 424,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 68,
			'scoped_name' => 419,
			'wide_char_type' => 70,
			'signed_long_int' => 71,
			'signed_short_int' => 97,
			'string_type' => 420,
			'op_param_type_spec' => 426,
			'sequence_type' => 427,
			'base_type_spec' => 421,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'unsigned_long_int' => 104,
			'param_type_spec' => 444,
			'unsigned_short_int' => 82,
			'fixed_pt_type' => 428,
			'signed_longlong_int' => 84
		}
	},
	{#State 350
		ACTIONS => {
			'IN' => 445,
			'OUT' => 448,
			'INOUT' => 446
		},
		DEFAULT => -327,
		GOTOS => {
			'param_attribute' => 447
		}
	},
	{#State 351
		ACTIONS => {
			")" => 449
		}
	},
	{#State 352
		ACTIONS => {
			")" => 450
		}
	},
	{#State 353
		ACTIONS => {
			")" => 452,
			"," => 451
		}
	},
	{#State 354
		DEFAULT => -317
	},
	{#State 355
		ACTIONS => {
			";" => 453
		},
		DEFAULT => -320
	},
	{#State 356
		ACTIONS => {
			'CONTEXT' => 454
		},
		DEFAULT => -338,
		GOTOS => {
			'context_expr' => 455
		}
	},
	{#State 357
		DEFAULT => -77
	},
	{#State 358
		ACTIONS => {
			"{" => -97,
			'SUPPORTS' => 458,
			":" => 457
		},
		DEFAULT => -70,
		GOTOS => {
			'supported_interface_spec' => 459,
			'value_inheritance_spec' => 456
		}
	},
	{#State 359
		DEFAULT => -85
	},
	{#State 360
		ACTIONS => {
			":" => 457,
			";" => -69,
			"{" => -97,
			'error' => -69,
			'SUPPORTS' => 458
		},
		DEFAULT => -72,
		GOTOS => {
			'supported_interface_spec' => 459,
			'value_inheritance_spec' => 460
		}
	},
	{#State 361
		ACTIONS => {
			"{" => -39
		},
		DEFAULT => -34
	},
	{#State 362
		ACTIONS => {
			"{" => -56,
			":" => 461
		},
		DEFAULT => -33,
		GOTOS => {
			'interface_inheritance_spec' => 462
		}
	},
	{#State 363
		DEFAULT => -214
	},
	{#State 364
		DEFAULT => -213
	},
	{#State 365
		DEFAULT => -181,
		GOTOS => {
			'@1-4' => 463
		}
	},
	{#State 366
		DEFAULT => -185
	},
	{#State 367
		DEFAULT => -240
	},
	{#State 368
		DEFAULT => -239
	},
	{#State 369
		ACTIONS => {
			'PROP_KEY' => 464
		}
	},
	{#State 370
		DEFAULT => -396
	},
	{#State 371
		DEFAULT => -397
	},
	{#State 372
		DEFAULT => -270
	},
	{#State 373
		DEFAULT => -277
	},
	{#State 374
		ACTIONS => {
			'IDENTIFIER' => 270
		},
		DEFAULT => -276,
		GOTOS => {
			'enumerators' => 465,
			'enumerator' => 269
		}
	},
	{#State 375
		DEFAULT => -269
	},
	{#State 376
		DEFAULT => -121
	},
	{#State 377
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'CHARACTER_LITERAL' => 276,
			'WIDE_CHARACTER_LITERAL' => 277,
			"::" => 96,
			'INTEGER_LITERAL' => 297,
			"(" => 281,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'FIXED_PT_LITERAL' => 299,
			"+" => 300,
			'error' => 467,
			"-" => 302,
			'WIDE_STRING_LITERAL' => 289,
			'FALSE' => 288,
			"~" => 303,
			'TRUE' => 291
		},
		GOTOS => {
			'mult_expr' => 298,
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'const_exp' => 466,
			'and_expr' => 296,
			'or_expr' => 284,
			'unary_expr' => 301,
			'scoped_name' => 278,
			'xor_expr' => 286,
			'shift_expr' => 287,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 378
		DEFAULT => -254
	},
	{#State 379
		ACTIONS => {
			'ENUM' => 159
		}
	},
	{#State 380
		ACTIONS => {
			"::" => 194
		},
		DEFAULT => -257
	},
	{#State 381
		DEFAULT => -256
	},
	{#State 382
		ACTIONS => {
			")" => 468
		}
	},
	{#State 383
		ACTIONS => {
			")" => 469
		}
	},
	{#State 384
		DEFAULT => -255
	},
	{#State 385
		DEFAULT => -253
	},
	{#State 386
		ACTIONS => {
			'LONG' => 198
		},
		DEFAULT => -225
	},
	{#State 387
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'CHARACTER_LITERAL' => 276,
			'WIDE_CHARACTER_LITERAL' => 277,
			"::" => 96,
			'INTEGER_LITERAL' => 297,
			"(" => 281,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'FIXED_PT_LITERAL' => 299,
			"+" => 300,
			'error' => 471,
			"-" => 302,
			'WIDE_STRING_LITERAL' => 289,
			'FALSE' => 288,
			"~" => 303,
			'TRUE' => 291
		},
		GOTOS => {
			'string_literal' => 293,
			'primary_expr' => 295,
			'and_expr' => 296,
			'scoped_name' => 278,
			'positive_int_const' => 470,
			'wide_string_literal' => 280,
			'boolean_literal' => 282,
			'mult_expr' => 298,
			'const_exp' => 283,
			'or_expr' => 284,
			'unary_expr' => 301,
			'xor_expr' => 286,
			'shift_expr' => 287,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 388
		ACTIONS => {
			")" => 472
		}
	},
	{#State 389
		ACTIONS => {
			")" => 473
		}
	},
	{#State 390
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			"+" => 300,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"-" => 302,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"~" => 303,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'mult_expr' => 298,
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'and_expr' => 296,
			'unary_expr' => 301,
			'scoped_name' => 278,
			'xor_expr' => 474,
			'shift_expr' => 287,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 391
		DEFAULT => -351
	},
	{#State 392
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			"+" => 300,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"-" => 302,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"~" => 303,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'mult_expr' => 298,
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'and_expr' => 475,
			'unary_expr' => 301,
			'scoped_name' => 278,
			'shift_expr' => 287,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 393
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			"+" => 300,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"-" => 302,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"~" => 303,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'mult_expr' => 298,
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'unary_expr' => 301,
			'scoped_name' => 278,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 476
		}
	},
	{#State 394
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			"+" => 300,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"-" => 302,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"~" => 303,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'mult_expr' => 298,
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'unary_expr' => 301,
			'scoped_name' => 278,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 477
		}
	},
	{#State 395
		DEFAULT => -171
	},
	{#State 396
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			"+" => 300,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"-" => 302,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"~" => 303,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'mult_expr' => 478,
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'unary_expr' => 301,
			'scoped_name' => 278,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304
		}
	},
	{#State 397
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			"+" => 300,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"-" => 302,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"~" => 303,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'mult_expr' => 479,
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'unary_expr' => 301,
			'scoped_name' => 278,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304
		}
	},
	{#State 398
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			"+" => 300,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"-" => 302,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"~" => 303,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'mult_expr' => 298,
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'unary_expr' => 301,
			'scoped_name' => 278,
			'shift_expr' => 480,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 399
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			"+" => 300,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"-" => 302,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"~" => 303,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'unary_expr' => 481,
			'scoped_name' => 278,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304
		}
	},
	{#State 400
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			"+" => 300,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"-" => 302,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"~" => 303,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'unary_expr' => 482,
			'scoped_name' => 278,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304
		}
	},
	{#State 401
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'CHARACTER_LITERAL' => 276,
			"+" => 300,
			'FIXED_PT_LITERAL' => 299,
			'WIDE_CHARACTER_LITERAL' => 277,
			"-" => 302,
			"::" => 96,
			'FALSE' => 288,
			'WIDE_STRING_LITERAL' => 289,
			'INTEGER_LITERAL' => 297,
			"~" => 303,
			"(" => 281,
			'TRUE' => 291
		},
		GOTOS => {
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'unary_expr' => 483,
			'scoped_name' => 278,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304
		}
	},
	{#State 402
		DEFAULT => -151
	},
	{#State 403
		DEFAULT => -282
	},
	{#State 404
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'CHARACTER_LITERAL' => 276,
			'WIDE_CHARACTER_LITERAL' => 277,
			"::" => 96,
			'INTEGER_LITERAL' => 297,
			"(" => 281,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'FIXED_PT_LITERAL' => 299,
			"+" => 300,
			'error' => 485,
			"-" => 302,
			'WIDE_STRING_LITERAL' => 289,
			'FALSE' => 288,
			"~" => 303,
			'TRUE' => 291
		},
		GOTOS => {
			'string_literal' => 293,
			'primary_expr' => 295,
			'and_expr' => 296,
			'scoped_name' => 278,
			'positive_int_const' => 484,
			'wide_string_literal' => 280,
			'boolean_literal' => 282,
			'mult_expr' => 298,
			'const_exp' => 283,
			'or_expr' => 284,
			'unary_expr' => 301,
			'xor_expr' => 286,
			'shift_expr' => 287,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 405
		DEFAULT => -281
	},
	{#State 406
		DEFAULT => -284
	},
	{#State 407
		DEFAULT => -286
	},
	{#State 408
		DEFAULT => -287
	},
	{#State 409
		DEFAULT => -289
	},
	{#State 410
		DEFAULT => -245
	},
	{#State 411
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 328
		},
		GOTOS => {
			'declarators' => 486,
			'declarator' => 324,
			'simple_declarator' => 326,
			'array_declarator' => 327,
			'complex_declarator' => 325
		}
	},
	{#State 412
		DEFAULT => -290
	},
	{#State 413
		ACTIONS => {
			"[" => 414
		},
		DEFAULT => -291,
		GOTOS => {
			'fixed_array_sizes' => 487,
			'fixed_array_size' => 413
		}
	},
	{#State 414
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'CHARACTER_LITERAL' => 276,
			'WIDE_CHARACTER_LITERAL' => 277,
			"::" => 96,
			'INTEGER_LITERAL' => 297,
			"(" => 281,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'FIXED_PT_LITERAL' => 299,
			"+" => 300,
			'error' => 489,
			"-" => 302,
			'WIDE_STRING_LITERAL' => 289,
			'FALSE' => 288,
			"~" => 303,
			'TRUE' => 291
		},
		GOTOS => {
			'string_literal' => 293,
			'primary_expr' => 295,
			'and_expr' => 296,
			'scoped_name' => 278,
			'positive_int_const' => 488,
			'wide_string_literal' => 280,
			'boolean_literal' => 282,
			'mult_expr' => 298,
			'const_exp' => 283,
			'or_expr' => 284,
			'unary_expr' => 301,
			'xor_expr' => 286,
			'shift_expr' => 287,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 415
		ACTIONS => {
			"::" => 194
		},
		DEFAULT => -334
	},
	{#State 416
		ACTIONS => {
			")" => 490
		}
	},
	{#State 417
		ACTIONS => {
			")" => 491
		}
	},
	{#State 418
		ACTIONS => {
			"," => 492
		},
		DEFAULT => -332
	},
	{#State 419
		ACTIONS => {
			"::" => 194
		},
		DEFAULT => -348
	},
	{#State 420
		DEFAULT => -346
	},
	{#State 421
		DEFAULT => -345
	},
	{#State 422
		DEFAULT => -117
	},
	{#State 423
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 256
		},
		GOTOS => {
			'simple_declarator' => 493
		}
	},
	{#State 424
		DEFAULT => -347
	},
	{#State 425
		DEFAULT => -342
	},
	{#State 426
		DEFAULT => -341
	},
	{#State 427
		DEFAULT => -343
	},
	{#State 428
		DEFAULT => -344
	},
	{#State 429
		DEFAULT => -109
	},
	{#State 430
		ACTIONS => {
			'IN' => 337
		},
		GOTOS => {
			'init_param_decls' => 494,
			'init_param_attribute' => 335,
			'init_param_decl' => 338
		}
	},
	{#State 431
		DEFAULT => -110
	},
	{#State 432
		DEFAULT => -311
	},
	{#State 433
		DEFAULT => -310
	},
	{#State 434
		ACTIONS => {
			'error' => 495,
			'IDENTIFIER' => 496
		}
	},
	{#State 435
		DEFAULT => -312
	},
	{#State 436
		DEFAULT => -313
	},
	{#State 437
		ACTIONS => {
			'error' => 498,
			'IDENTIFIER' => 328
		},
		GOTOS => {
			'declarators' => 497,
			'declarator' => 324,
			'simple_declarator' => 326,
			'array_declarator' => 327,
			'complex_declarator' => 325
		}
	},
	{#State 438
		ACTIONS => {
			";" => 499
		}
	},
	{#State 439
		DEFAULT => -113
	},
	{#State 440
		DEFAULT => -112
	},
	{#State 441
		DEFAULT => -372
	},
	{#State 442
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 425,
			'SEQUENCE' => 63,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'WCHAR' => 76,
			'error' => 500,
			'FLOAT' => 83,
			'OCTET' => 81,
			'ANY' => 85
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 424,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 68,
			'scoped_name' => 419,
			'wide_char_type' => 70,
			'signed_long_int' => 71,
			'signed_short_int' => 97,
			'string_type' => 420,
			'op_param_type_spec' => 426,
			'sequence_type' => 427,
			'base_type_spec' => 421,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'unsigned_long_int' => 104,
			'param_type_spec' => 501,
			'unsigned_short_int' => 82,
			'fixed_pt_type' => 428,
			'signed_longlong_int' => 84
		}
	},
	{#State 443
		DEFAULT => -378
	},
	{#State 444
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 256
		},
		GOTOS => {
			'attr_declarator' => 503,
			'simple_declarator' => 502
		}
	},
	{#State 445
		DEFAULT => -324
	},
	{#State 446
		DEFAULT => -326
	},
	{#State 447
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 425,
			'SEQUENCE' => 63,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'WCHAR' => 76,
			'FLOAT' => 83,
			'OCTET' => 81,
			'ANY' => 85
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 424,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 68,
			'scoped_name' => 419,
			'wide_char_type' => 70,
			'signed_long_int' => 71,
			'signed_short_int' => 97,
			'string_type' => 420,
			'op_param_type_spec' => 426,
			'sequence_type' => 427,
			'base_type_spec' => 421,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'unsigned_long_int' => 104,
			'param_type_spec' => 504,
			'unsigned_short_int' => 82,
			'fixed_pt_type' => 428,
			'signed_longlong_int' => 84
		}
	},
	{#State 448
		DEFAULT => -325
	},
	{#State 449
		DEFAULT => -318
	},
	{#State 450
		DEFAULT => -319
	},
	{#State 451
		ACTIONS => {
			"..." => 505,
			")" => 506,
			"[" => 48
		},
		DEFAULT => -394,
		GOTOS => {
			'props' => 350,
			'param_dcl' => 507
		}
	},
	{#State 452
		DEFAULT => -314
	},
	{#State 453
		DEFAULT => -322
	},
	{#State 454
		ACTIONS => {
			'error' => 509,
			"(" => 508
		}
	},
	{#State 455
		DEFAULT => -303
	},
	{#State 456
		DEFAULT => -76
	},
	{#State 457
		ACTIONS => {
			'TRUNCATABLE' => 511
		},
		DEFAULT => -92,
		GOTOS => {
			'inheritance_mod' => 510
		}
	},
	{#State 458
		ACTIONS => {
			'error' => 513,
			'IDENTIFIER' => 102,
			"::" => 96
		},
		GOTOS => {
			'scoped_name' => 512,
			'interface_names' => 515,
			'interface_name' => 514
		}
	},
	{#State 459
		DEFAULT => -90
	},
	{#State 460
		DEFAULT => -84
	},
	{#State 461
		ACTIONS => {
			'error' => 516,
			'IDENTIFIER' => 102,
			"::" => 96
		},
		GOTOS => {
			'scoped_name' => 512,
			'interface_names' => 517,
			'interface_name' => 514
		}
	},
	{#State 462
		DEFAULT => -38
	},
	{#State 463
		ACTIONS => {
			'NATIVE_TYPE' => 518
		}
	},
	{#State 464
		ACTIONS => {
			'PROP_VALUE' => 519
		},
		DEFAULT => -400
	},
	{#State 465
		DEFAULT => -275
	},
	{#State 466
		DEFAULT => -119
	},
	{#State 467
		DEFAULT => -120
	},
	{#State 468
		DEFAULT => -249
	},
	{#State 469
		ACTIONS => {
			"{" => 521,
			'error' => 520
		}
	},
	{#State 470
		ACTIONS => {
			">" => 522
		}
	},
	{#State 471
		ACTIONS => {
			">" => 523
		}
	},
	{#State 472
		DEFAULT => -158
	},
	{#State 473
		DEFAULT => -159
	},
	{#State 474
		ACTIONS => {
			"^" => 392
		},
		DEFAULT => -136
	},
	{#State 475
		ACTIONS => {
			"&" => 398
		},
		DEFAULT => -138
	},
	{#State 476
		ACTIONS => {
			"+" => 396,
			"-" => 397
		},
		DEFAULT => -143
	},
	{#State 477
		ACTIONS => {
			"+" => 396,
			"-" => 397
		},
		DEFAULT => -142
	},
	{#State 478
		ACTIONS => {
			"%" => 400,
			"*" => 399,
			"/" => 401
		},
		DEFAULT => -145
	},
	{#State 479
		ACTIONS => {
			"%" => 400,
			"*" => 399,
			"/" => 401
		},
		DEFAULT => -146
	},
	{#State 480
		ACTIONS => {
			"<<" => 393,
			">>" => 394
		},
		DEFAULT => -140
	},
	{#State 481
		DEFAULT => -148
	},
	{#State 482
		DEFAULT => -150
	},
	{#State 483
		DEFAULT => -149
	},
	{#State 484
		ACTIONS => {
			">" => 524
		}
	},
	{#State 485
		ACTIONS => {
			">" => 525
		}
	},
	{#State 486
		DEFAULT => -209
	},
	{#State 487
		DEFAULT => -292
	},
	{#State 488
		ACTIONS => {
			"]" => 526
		}
	},
	{#State 489
		ACTIONS => {
			"]" => 527
		}
	},
	{#State 490
		DEFAULT => -329
	},
	{#State 491
		DEFAULT => -328
	},
	{#State 492
		ACTIONS => {
			'IDENTIFIER' => 102,
			"::" => 96
		},
		GOTOS => {
			'scoped_name' => 415,
			'exception_names' => 528,
			'exception_name' => 418
		}
	},
	{#State 493
		DEFAULT => -116
	},
	{#State 494
		DEFAULT => -115
	},
	{#State 495
		DEFAULT => -306
	},
	{#State 496
		DEFAULT => -305
	},
	{#State 497
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 529
		}
	},
	{#State 498
		ACTIONS => {
			";" => 530,
			"," => 364
		}
	},
	{#State 499
		DEFAULT => -104
	},
	{#State 500
		DEFAULT => -371
	},
	{#State 501
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 256
		},
		GOTOS => {
			'simple_declarator' => 532,
			'readonly_attr_declarator' => 531
		}
	},
	{#State 502
		ACTIONS => {
			'GETRAISES' => 538,
			'SETRAISES' => 537,
			"," => 535
		},
		DEFAULT => -384,
		GOTOS => {
			'set_except_expr' => 533,
			'get_except_expr' => 534,
			'attr_raises_expr' => 536
		}
	},
	{#State 503
		DEFAULT => -377
	},
	{#State 504
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 256
		},
		GOTOS => {
			'simple_declarator' => 539
		}
	},
	{#State 505
		ACTIONS => {
			")" => 540
		}
	},
	{#State 506
		DEFAULT => -316
	},
	{#State 507
		DEFAULT => -321
	},
	{#State 508
		ACTIONS => {
			'error' => 541,
			'STRING_LITERAL' => 119
		},
		GOTOS => {
			'string_literal' => 542,
			'string_literals' => 543
		}
	},
	{#State 509
		DEFAULT => -337
	},
	{#State 510
		ACTIONS => {
			'error' => 546,
			'IDENTIFIER' => 102,
			"::" => 96
		},
		GOTOS => {
			'scoped_name' => 544,
			'value_name' => 545,
			'value_names' => 547
		}
	},
	{#State 511
		DEFAULT => -91
	},
	{#State 512
		ACTIONS => {
			"::" => 194
		},
		DEFAULT => -59
	},
	{#State 513
		DEFAULT => -96
	},
	{#State 514
		ACTIONS => {
			"," => 548
		},
		DEFAULT => -57
	},
	{#State 515
		DEFAULT => -95
	},
	{#State 516
		DEFAULT => -55
	},
	{#State 517
		DEFAULT => -54
	},
	{#State 518
		DEFAULT => -182
	},
	{#State 519
		DEFAULT => -398
	},
	{#State 520
		DEFAULT => -248
	},
	{#State 521
		ACTIONS => {
			'error' => 552,
			'CASE' => 549,
			'DEFAULT' => 551
		},
		GOTOS => {
			'case_labels' => 554,
			'switch_body' => 553,
			'case' => 550,
			'case_label' => 555
		}
	},
	{#State 522
		DEFAULT => -349
	},
	{#State 523
		DEFAULT => -350
	},
	{#State 524
		DEFAULT => -279
	},
	{#State 525
		DEFAULT => -280
	},
	{#State 526
		DEFAULT => -293
	},
	{#State 527
		DEFAULT => -294
	},
	{#State 528
		DEFAULT => -333
	},
	{#State 529
		DEFAULT => -102
	},
	{#State 530
		ACTIONS => {
			";" => -214,
			"," => -214,
			'error' => -214
		},
		DEFAULT => -103
	},
	{#State 531
		DEFAULT => -370
	},
	{#State 532
		ACTIONS => {
			'RAISES' => 231,
			"," => 556
		},
		DEFAULT => -331,
		GOTOS => {
			'raises_expr' => 557
		}
	},
	{#State 533
		DEFAULT => -383
	},
	{#State 534
		ACTIONS => {
			'SETRAISES' => 537
		},
		DEFAULT => -382,
		GOTOS => {
			'set_except_expr' => 558
		}
	},
	{#State 535
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 256
		},
		GOTOS => {
			'simple_declarators' => 560,
			'simple_declarator' => 559
		}
	},
	{#State 536
		DEFAULT => -379
	},
	{#State 537
		ACTIONS => {
			'error' => 562,
			"(" => 561
		},
		GOTOS => {
			'exception_list' => 563
		}
	},
	{#State 538
		ACTIONS => {
			'error' => 564,
			"(" => 561
		},
		GOTOS => {
			'exception_list' => 565
		}
	},
	{#State 539
		DEFAULT => -323
	},
	{#State 540
		DEFAULT => -315
	},
	{#State 541
		ACTIONS => {
			")" => 566
		}
	},
	{#State 542
		ACTIONS => {
			"," => 567
		},
		DEFAULT => -339
	},
	{#State 543
		ACTIONS => {
			")" => 568
		}
	},
	{#State 544
		ACTIONS => {
			"::" => 194
		},
		DEFAULT => -98
	},
	{#State 545
		ACTIONS => {
			"," => 569
		},
		DEFAULT => -93
	},
	{#State 546
		DEFAULT => -89
	},
	{#State 547
		ACTIONS => {
			'SUPPORTS' => 458
		},
		DEFAULT => -97,
		GOTOS => {
			'supported_interface_spec' => 570
		}
	},
	{#State 548
		ACTIONS => {
			'IDENTIFIER' => 102,
			"::" => 96
		},
		GOTOS => {
			'scoped_name' => 512,
			'interface_names' => 571,
			'interface_name' => 514
		}
	},
	{#State 549
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 294,
			'CHARACTER_LITERAL' => 276,
			'WIDE_CHARACTER_LITERAL' => 277,
			"::" => 96,
			'INTEGER_LITERAL' => 297,
			"(" => 281,
			'IDENTIFIER' => 102,
			'STRING_LITERAL' => 119,
			'FIXED_PT_LITERAL' => 299,
			"+" => 300,
			'error' => 573,
			"-" => 302,
			'WIDE_STRING_LITERAL' => 289,
			'FALSE' => 288,
			"~" => 303,
			'TRUE' => 291
		},
		GOTOS => {
			'mult_expr' => 298,
			'string_literal' => 293,
			'boolean_literal' => 282,
			'primary_expr' => 295,
			'const_exp' => 572,
			'and_expr' => 296,
			'or_expr' => 284,
			'unary_expr' => 301,
			'scoped_name' => 278,
			'xor_expr' => 286,
			'shift_expr' => 287,
			'wide_string_literal' => 280,
			'literal' => 290,
			'unary_operator' => 304,
			'add_expr' => 292
		}
	},
	{#State 550
		ACTIONS => {
			'CASE' => 549,
			'DEFAULT' => 551
		},
		DEFAULT => -258,
		GOTOS => {
			'case_labels' => 554,
			'switch_body' => 574,
			'case' => 550,
			'case_label' => 555
		}
	},
	{#State 551
		ACTIONS => {
			'error' => 575,
			":" => 576
		}
	},
	{#State 552
		ACTIONS => {
			"}" => 577
		}
	},
	{#State 553
		ACTIONS => {
			"}" => 578
		}
	},
	{#State 554
		ACTIONS => {
			'CHAR' => 86,
			'OBJECT' => 87,
			'VALUEBASE' => 88,
			'FIXED' => 61,
			'VOID' => 90,
			'SEQUENCE' => 63,
			'DOUBLE' => 93,
			'LONG' => 94,
			'STRING' => 95,
			"::" => 96,
			'WSTRING' => 98,
			'UNSIGNED' => 73,
			'SHORT' => 75,
			'BOOLEAN' => 100,
			'IDENTIFIER' => 102,
			'WCHAR' => 76,
			"[" => 48,
			'OCTET' => 81,
			'FLOAT' => 83,
			'ANY' => 85
		},
		DEFAULT => -394,
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'props' => 67,
			'octet_type' => 68,
			'scoped_name' => 69,
			'wide_char_type' => 70,
			'signed_long_int' => 71,
			'type_spec' => 579,
			'string_type' => 74,
			'struct_header' => 46,
			'element_spec' => 580,
			'unsigned_longlong_int' => 77,
			'any_type' => 78,
			'base_type_spec' => 79,
			'enum_type' => 80,
			'enum_header' => 51,
			'union_header' => 54,
			'unsigned_short_int' => 82,
			'signed_longlong_int' => 84,
			'wide_string_type' => 89,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 97,
			'struct_type' => 99,
			'union_type' => 101,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 555
		ACTIONS => {
			'CASE' => 549,
			'DEFAULT' => 551
		},
		DEFAULT => -261,
		GOTOS => {
			'case_labels' => 581,
			'case_label' => 555
		}
	},
	{#State 556
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 256
		},
		GOTOS => {
			'simple_declarators' => 582,
			'simple_declarator' => 559
		}
	},
	{#State 557
		DEFAULT => -373
	},
	{#State 558
		DEFAULT => -381
	},
	{#State 559
		ACTIONS => {
			"," => 583
		},
		DEFAULT => -375
	},
	{#State 560
		DEFAULT => -380
	},
	{#State 561
		ACTIONS => {
			'error' => 584,
			'IDENTIFIER' => 102,
			"::" => 96
		},
		GOTOS => {
			'scoped_name' => 415,
			'exception_names' => 585,
			'exception_name' => 418
		}
	},
	{#State 562
		DEFAULT => -388
	},
	{#State 563
		DEFAULT => -387
	},
	{#State 564
		DEFAULT => -386
	},
	{#State 565
		DEFAULT => -385
	},
	{#State 566
		DEFAULT => -336
	},
	{#State 567
		ACTIONS => {
			'STRING_LITERAL' => 119
		},
		GOTOS => {
			'string_literal' => 542,
			'string_literals' => 586
		}
	},
	{#State 568
		DEFAULT => -335
	},
	{#State 569
		ACTIONS => {
			'IDENTIFIER' => 102,
			"::" => 96
		},
		GOTOS => {
			'scoped_name' => 544,
			'value_name' => 545,
			'value_names' => 587
		}
	},
	{#State 570
		DEFAULT => -88
	},
	{#State 571
		DEFAULT => -58
	},
	{#State 572
		ACTIONS => {
			'error' => 588,
			":" => 589
		}
	},
	{#State 573
		DEFAULT => -265
	},
	{#State 574
		DEFAULT => -259
	},
	{#State 575
		DEFAULT => -267
	},
	{#State 576
		DEFAULT => -266
	},
	{#State 577
		DEFAULT => -247
	},
	{#State 578
		DEFAULT => -246
	},
	{#State 579
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 328
		},
		GOTOS => {
			'declarator' => 590,
			'simple_declarator' => 326,
			'array_declarator' => 327,
			'complex_declarator' => 325
		}
	},
	{#State 580
		ACTIONS => {
			'error' => 35,
			";" => 34
		},
		GOTOS => {
			'check_semicolon' => 591
		}
	},
	{#State 581
		DEFAULT => -262
	},
	{#State 582
		DEFAULT => -374
	},
	{#State 583
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 256
		},
		GOTOS => {
			'simple_declarators' => 592,
			'simple_declarator' => 559
		}
	},
	{#State 584
		ACTIONS => {
			")" => 593
		}
	},
	{#State 585
		ACTIONS => {
			")" => 594
		}
	},
	{#State 586
		DEFAULT => -340
	},
	{#State 587
		DEFAULT => -94
	},
	{#State 588
		DEFAULT => -264
	},
	{#State 589
		DEFAULT => -263
	},
	{#State 590
		DEFAULT => -268
	},
	{#State 591
		DEFAULT => -260
	},
	{#State 592
		DEFAULT => -376
	},
	{#State 593
		DEFAULT => -390
	},
	{#State 594
		DEFAULT => -389
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'specification', 1,
sub
#line 79 "parserxp.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 2,
sub
#line 85 "parserxp.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_import'		=>	$_[1],
					'list_decl'			=>	$_[2],
			);
		}
	],
	[#Rule 3
		 'specification', 0,
sub
#line 92 "parserxp.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 4
		 'specification', 1,
sub
#line 96 "parserxp.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 5
		 'imports', 1,
sub
#line 103 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 6
		 'imports', 2,
sub
#line 107 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 7
		 'definitions', 1,
sub
#line 115 "parserxp.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 8
		 'definitions', 2,
sub
#line 119 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 9
		 'definitions', 3,
sub
#line 124 "parserxp.yp"
{
			$_[0]->Error("import after definition.\n");
			unshift(@{$_[3]},$_[1]->getRef());
			$_[3];
		}
	],
	[#Rule 10
		 'definition', 2, undef
	],
	[#Rule 11
		 'definition', 2, undef
	],
	[#Rule 12
		 'definition', 2, undef
	],
	[#Rule 13
		 'definition', 2, undef
	],
	[#Rule 14
		 'definition', 2, undef
	],
	[#Rule 15
		 'definition', 2, undef
	],
	[#Rule 16
		 'definition', 2, undef
	],
	[#Rule 17
		 'definition', 2, undef
	],
	[#Rule 18
		 'definition', 1, undef
	],
	[#Rule 19
		 'definition', 3,
sub
#line 152 "parserxp.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 20
		 'check_semicolon', 1, undef
	],
	[#Rule 21
		 'check_semicolon', 1,
sub
#line 166 "parserxp.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 22
		 'module', 4,
sub
#line 175 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 23
		 'module', 4,
sub
#line 182 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 24
		 'module', 3,
sub
#line 188 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 25
		 'module', 3,
sub
#line 194 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 26
		 'module_header', 3,
sub
#line 203 "parserxp.yp"
{
			new Module($_[0],
					'declspec'			=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 27
		 'module_header', 3,
sub
#line 210 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'interface', 1, undef
	],
	[#Rule 29
		 'interface', 1, undef
	],
	[#Rule 30
		 'interface_dcl', 3,
sub
#line 227 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 31
		 'interface_dcl', 4,
sub
#line 235 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 32
		 'interface_dcl', 4,
sub
#line 243 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 33
		 'forward_dcl', 5,
sub
#line 254 "parserxp.yp"
{
			$_[0]->Warning("Ignoring properties for forward declaration.\n")
					if (defined $_[2]);
			if (defined $_[3] and $_[3] eq 'abstract') {
				new ForwardAbstractInterface($_[0],
						'declspec'				=>	$_[1],
						'idf'					=>	$_[5]
				);
			} elsif (defined $_[3] and $_[3] eq 'local') {
				new ForwardLocalInterface($_[0],
						'declspec'				=>	$_[1],
						'idf'					=>	$_[5]
				);
			} else {
				new ForwardRegularInterface($_[0],
						'declspec'				=>	$_[1],
						'idf'					=>	$_[5]
				);
			}
		}
	],
	[#Rule 34
		 'forward_dcl', 5,
sub
#line 275 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 35
		 'interface_mod', 1, undef
	],
	[#Rule 36
		 'interface_mod', 1, undef
	],
	[#Rule 37
		 'interface_mod', 0, undef
	],
	[#Rule 38
		 'interface_header', 6,
sub
#line 293 "parserxp.yp"
{
			if (defined $_[3] and $_[3] eq 'abstract') {
				new AbstractInterface($_[0],
						'declspec'				=>	$_[1],
						'props'					=>	$_[2],
						'idf'					=>	$_[5],
						'inheritance'			=>	$_[6]
				);
			} elsif (defined $_[3] and $_[3] eq 'local') {
				new LocalInterface($_[0],
						'declspec'				=>	$_[1],
						'props'					=>	$_[2],
						'idf'					=>	$_[5],
						'inheritance'			=>	$_[6]
				);
			} else {
				new RegularInterface($_[0],
						'declspec'				=>	$_[1],
						'props'					=>	$_[2],
						'idf'					=>	$_[5],
						'inheritance'			=>	$_[6]
				);
			}
		}
	],
	[#Rule 39
		 'interface_header', 5,
sub
#line 318 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 40
		 'interface_body', 1, undef
	],
	[#Rule 41
		 'exports', 1,
sub
#line 332 "parserxp.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 42
		 'exports', 2,
sub
#line 336 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 43
		 '_export', 1, undef
	],
	[#Rule 44
		 '_export', 1,
sub
#line 347 "parserxp.yp"
{
			$_[0]->Error("state member unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 45
		 '_export', 1,
sub
#line 352 "parserxp.yp"
{
			$_[0]->Error("initializer unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 46
		 'export', 2, undef
	],
	[#Rule 47
		 'export', 2, undef
	],
	[#Rule 48
		 'export', 2, undef
	],
	[#Rule 49
		 'export', 2, undef
	],
	[#Rule 50
		 'export', 2, undef
	],
	[#Rule 51
		 'export', 2, undef
	],
	[#Rule 52
		 'export', 2, undef
	],
	[#Rule 53
		 'export', 1, undef
	],
	[#Rule 54
		 'interface_inheritance_spec', 2,
sub
#line 380 "parserxp.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'		=>	$_[2]
			);
		}
	],
	[#Rule 55
		 'interface_inheritance_spec', 2,
sub
#line 386 "parserxp.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 56
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 57
		 'interface_names', 1,
sub
#line 396 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 58
		 'interface_names', 3,
sub
#line 400 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 59
		 'interface_name', 1,
sub
#line 409 "parserxp.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 60
		 'scoped_name', 1, undef
	],
	[#Rule 61
		 'scoped_name', 2,
sub
#line 419 "parserxp.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 62
		 'scoped_name', 2,
sub
#line 423 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 63
		 'scoped_name', 3,
sub
#line 429 "parserxp.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 64
		 'scoped_name', 3,
sub
#line 433 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 65
		 'value', 1, undef
	],
	[#Rule 66
		 'value', 1, undef
	],
	[#Rule 67
		 'value', 1, undef
	],
	[#Rule 68
		 'value', 1, undef
	],
	[#Rule 69
		 'value_forward_dcl', 5,
sub
#line 455 "parserxp.yp"
{
			$_[0]->Warning("Ignoring properties for forward declaration.\n")
					if (defined $_[2]);
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[3]);
			new ForwardRegularValue($_[0],
					'declspec'			=>	$_[1],
					'idf'				=>	$_[4]
			);
		}
	],
	[#Rule 70
		 'value_forward_dcl', 5,
sub
#line 466 "parserxp.yp"
{
			$_[0]->Warning("Ignoring properties for forward declaration.\n")
					if (defined $_[2]);
			new ForwardAbstractValue($_[0],
					'declspec'			=>	$_[1],
					'idf'				=>	$_[5]
			);
		}
	],
	[#Rule 71
		 'value_box_dcl', 2,
sub
#line 479 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'type'				=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 72
		 'value_box_header', 5,
sub
#line 490 "parserxp.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[3]);
			new BoxedValue($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'idf'				=>	$_[4],
			);
		}
	],
	[#Rule 73
		 'value_abs_dcl', 3,
sub
#line 504 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 74
		 'value_abs_dcl', 4,
sub
#line 512 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 75
		 'value_abs_dcl', 4,
sub
#line 520 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 76
		 'value_abs_header', 6,
sub
#line 530 "parserxp.yp"
{
			new AbstractValue($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'idf'				=>	$_[5],
					'inheritance'		=>	$_[6]
			);
		}
	],
	[#Rule 77
		 'value_abs_header', 5,
sub
#line 539 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 78
		 'value_abs_header', 4,
sub
#line 544 "parserxp.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 79
		 'value_dcl', 3,
sub
#line 553 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 80
		 'value_dcl', 4,
sub
#line 561 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 81
		 'value_dcl', 4,
sub
#line 569 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 82
		 'value_elements', 1,
sub
#line 579 "parserxp.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 83
		 'value_elements', 2,
sub
#line 583 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 84
		 'value_header', 6,
sub
#line 592 "parserxp.yp"
{
			new RegularValue($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'modifier'			=>	$_[3],
					'idf'				=>	$_[5],
					'inheritance'		=>	$_[6]
			);
		}
	],
	[#Rule 85
		 'value_header', 5,
sub
#line 602 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 86
		 'value_mod', 1, undef
	],
	[#Rule 87
		 'value_mod', 0, undef
	],
	[#Rule 88
		 'value_inheritance_spec', 4,
sub
#line 618 "parserxp.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 89
		 'value_inheritance_spec', 3,
sub
#line 626 "parserxp.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 90
		 'value_inheritance_spec', 1,
sub
#line 631 "parserxp.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 91
		 'inheritance_mod', 1, undef
	],
	[#Rule 92
		 'inheritance_mod', 0, undef
	],
	[#Rule 93
		 'value_names', 1,
sub
#line 647 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 94
		 'value_names', 3,
sub
#line 651 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 95
		 'supported_interface_spec', 2,
sub
#line 659 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 96
		 'supported_interface_spec', 2,
sub
#line 663 "parserxp.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 97
		 'supported_interface_spec', 0, undef
	],
	[#Rule 98
		 'value_name', 1,
sub
#line 674 "parserxp.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 99
		 'value_element', 1, undef
	],
	[#Rule 100
		 'value_element', 1, undef
	],
	[#Rule 101
		 'value_element', 1, undef
	],
	[#Rule 102
		 'state_member', 6,
sub
#line 692 "parserxp.yp"
{
			new StateMembers($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'modifier'			=>	$_[3],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 103
		 'state_member', 6,
sub
#line 702 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 104
		 'state_member', 5,
sub
#line 707 "parserxp.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 105
		 'state_mod', 1, undef
	],
	[#Rule 106
		 'state_mod', 1, undef
	],
	[#Rule 107
		 'init_dcl', 3,
sub
#line 723 "parserxp.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 108
		 'init_header_param', 3,
sub
#line 732 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 109
		 'init_header_param', 4,
sub
#line 738 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 110
		 'init_header_param', 4,
sub
#line 746 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 111
		 'init_header_param', 2,
sub
#line 753 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 112
		 'init_header', 4,
sub
#line 763 "parserxp.yp"
{
			new Initializer($_[0],						# like Operation
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'idf'				=>	$_[4]
			);
		}
	],
	[#Rule 113
		 'init_header', 4,
sub
#line 771 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 114
		 'init_param_decls', 1,
sub
#line 780 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 115
		 'init_param_decls', 3,
sub
#line 784 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 116
		 'init_param_decl', 3,
sub
#line 793 "parserxp.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 117
		 'init_param_decl', 2,
sub
#line 801 "parserxp.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 118
		 'init_param_attribute', 1, undef
	],
	[#Rule 119
		 'const_dcl', 6,
sub
#line 816 "parserxp.yp"
{
			new Constant($_[0],
					'declspec'			=>	$_[1],
					'type'				=>	$_[3],
					'idf'				=>	$_[4],
					'list_expr'			=>	$_[6]
			);
		}
	],
	[#Rule 120
		 'const_dcl', 6,
sub
#line 825 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 121
		 'const_dcl', 5,
sub
#line 830 "parserxp.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 122
		 'const_dcl', 4,
sub
#line 835 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 123
		 'const_dcl', 3,
sub
#line 840 "parserxp.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 124
		 'const_type', 1, undef
	],
	[#Rule 125
		 'const_type', 1, undef
	],
	[#Rule 126
		 'const_type', 1, undef
	],
	[#Rule 127
		 'const_type', 1, undef
	],
	[#Rule 128
		 'const_type', 1, undef
	],
	[#Rule 129
		 'const_type', 1, undef
	],
	[#Rule 130
		 'const_type', 1, undef
	],
	[#Rule 131
		 'const_type', 1, undef
	],
	[#Rule 132
		 'const_type', 1,
sub
#line 865 "parserxp.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 133
		 'const_type', 1, undef
	],
	[#Rule 134
		 'const_exp', 1, undef
	],
	[#Rule 135
		 'or_expr', 1, undef
	],
	[#Rule 136
		 'or_expr', 3,
sub
#line 883 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 137
		 'xor_expr', 1, undef
	],
	[#Rule 138
		 'xor_expr', 3,
sub
#line 893 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 139
		 'and_expr', 1, undef
	],
	[#Rule 140
		 'and_expr', 3,
sub
#line 903 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 141
		 'shift_expr', 1, undef
	],
	[#Rule 142
		 'shift_expr', 3,
sub
#line 913 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 143
		 'shift_expr', 3,
sub
#line 917 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 144
		 'add_expr', 1, undef
	],
	[#Rule 145
		 'add_expr', 3,
sub
#line 927 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 146
		 'add_expr', 3,
sub
#line 931 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 147
		 'mult_expr', 1, undef
	],
	[#Rule 148
		 'mult_expr', 3,
sub
#line 941 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 149
		 'mult_expr', 3,
sub
#line 945 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 150
		 'mult_expr', 3,
sub
#line 949 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 151
		 'unary_expr', 2,
sub
#line 957 "parserxp.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 152
		 'unary_expr', 1, undef
	],
	[#Rule 153
		 'unary_operator', 1, undef
	],
	[#Rule 154
		 'unary_operator', 1, undef
	],
	[#Rule 155
		 'unary_operator', 1, undef
	],
	[#Rule 156
		 'primary_expr', 1,
sub
#line 977 "parserxp.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 157
		 'primary_expr', 1,
sub
#line 983 "parserxp.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 158
		 'primary_expr', 3,
sub
#line 987 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 159
		 'primary_expr', 3,
sub
#line 991 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 160
		 'literal', 1,
sub
#line 1000 "parserxp.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 161
		 'literal', 1,
sub
#line 1007 "parserxp.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 1013 "parserxp.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'literal', 1,
sub
#line 1019 "parserxp.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 164
		 'literal', 1,
sub
#line 1025 "parserxp.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 165
		 'literal', 1,
sub
#line 1031 "parserxp.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 166
		 'literal', 1,
sub
#line 1038 "parserxp.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 167
		 'literal', 1, undef
	],
	[#Rule 168
		 'string_literal', 1, undef
	],
	[#Rule 169
		 'string_literal', 2,
sub
#line 1052 "parserxp.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 170
		 'wide_string_literal', 1, undef
	],
	[#Rule 171
		 'wide_string_literal', 2,
sub
#line 1061 "parserxp.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 172
		 'boolean_literal', 1,
sub
#line 1069 "parserxp.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 173
		 'boolean_literal', 1,
sub
#line 1075 "parserxp.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 174
		 'positive_int_const', 1,
sub
#line 1085 "parserxp.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 175
		 'type_dcl', 2,
sub
#line 1095 "parserxp.yp"
{
			$_[2]->configure(
					'declspec'			=>	$_[1]
			) if ($_[2]);
		}
	],
	[#Rule 176
		 'type_dcl_def', 3,
sub
#line 1104 "parserxp.yp"
{
			$_[3]->configure(
					'props'				=>	$_[1]
			);
		}
	],
	[#Rule 177
		 'type_dcl_def', 1, undef
	],
	[#Rule 178
		 'type_dcl_def', 1, undef
	],
	[#Rule 179
		 'type_dcl_def', 1, undef
	],
	[#Rule 180
		 'type_dcl_def', 3,
sub
#line 1116 "parserxp.yp"
{
			new TypeDeclarator($_[0],
					'props'				=>	$_[1],
					'modifier'			=>	$_[2],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 181
		 '@1-4', 0,
sub
#line 1124 "parserxp.yp"
{
			$_[0]->YYData->{native} = 1;
		}
	],
	[#Rule 182
		 'type_dcl_def', 6,
sub
#line 1128 "parserxp.yp"
{
			$_[0]->YYData->{native} = 0;
			new TypeDeclarator($_[0],
					'props'				=>	$_[1],
					'modifier'			=>	$_[2],
					'idf'				=>	$_[3],
					'native'			=>	$_[6],
			);
		}
	],
	[#Rule 183
		 'type_dcl_def', 1, undef
	],
	[#Rule 184
		 'type_dcl_def', 3,
sub
#line 1140 "parserxp.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 185
		 'type_declarator', 2,
sub
#line 1149 "parserxp.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 186
		 'type_spec', 1, undef
	],
	[#Rule 187
		 'type_spec', 1, undef
	],
	[#Rule 188
		 'simple_type_spec', 1, undef
	],
	[#Rule 189
		 'simple_type_spec', 1, undef
	],
	[#Rule 190
		 'simple_type_spec', 1,
sub
#line 1172 "parserxp.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 191
		 'simple_type_spec', 1,
sub
#line 1176 "parserxp.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 192
		 'base_type_spec', 1, undef
	],
	[#Rule 193
		 'base_type_spec', 1, undef
	],
	[#Rule 194
		 'base_type_spec', 1, undef
	],
	[#Rule 195
		 'base_type_spec', 1, undef
	],
	[#Rule 196
		 'base_type_spec', 1, undef
	],
	[#Rule 197
		 'base_type_spec', 1, undef
	],
	[#Rule 198
		 'base_type_spec', 1, undef
	],
	[#Rule 199
		 'base_type_spec', 1, undef
	],
	[#Rule 200
		 'base_type_spec', 1, undef
	],
	[#Rule 201
		 'template_type_spec', 1, undef
	],
	[#Rule 202
		 'template_type_spec', 1, undef
	],
	[#Rule 203
		 'template_type_spec', 1, undef
	],
	[#Rule 204
		 'template_type_spec', 1, undef
	],
	[#Rule 205
		 'constr_type_spec', 1, undef
	],
	[#Rule 206
		 'constr_type_spec', 1, undef
	],
	[#Rule 207
		 'constr_type_spec', 1, undef
	],
	[#Rule 208
		 'declarators', 1,
sub
#line 1231 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 209
		 'declarators', 3,
sub
#line 1235 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 210
		 'declarator', 1,
sub
#line 1244 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 211
		 'declarator', 1, undef
	],
	[#Rule 212
		 'simple_declarator', 1, undef
	],
	[#Rule 213
		 'simple_declarator', 2,
sub
#line 1256 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 214
		 'simple_declarator', 2,
sub
#line 1261 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 215
		 'complex_declarator', 1, undef
	],
	[#Rule 216
		 'floating_pt_type', 1,
sub
#line 1276 "parserxp.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 217
		 'floating_pt_type', 1,
sub
#line 1282 "parserxp.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 218
		 'floating_pt_type', 2,
sub
#line 1288 "parserxp.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 219
		 'integer_type', 1, undef
	],
	[#Rule 220
		 'integer_type', 1, undef
	],
	[#Rule 221
		 'signed_int', 1, undef
	],
	[#Rule 222
		 'signed_int', 1, undef
	],
	[#Rule 223
		 'signed_int', 1, undef
	],
	[#Rule 224
		 'signed_short_int', 1,
sub
#line 1316 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 225
		 'signed_long_int', 1,
sub
#line 1326 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 226
		 'signed_longlong_int', 2,
sub
#line 1336 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 227
		 'unsigned_int', 1, undef
	],
	[#Rule 228
		 'unsigned_int', 1, undef
	],
	[#Rule 229
		 'unsigned_int', 1, undef
	],
	[#Rule 230
		 'unsigned_short_int', 2,
sub
#line 1356 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 231
		 'unsigned_long_int', 2,
sub
#line 1366 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 232
		 'unsigned_longlong_int', 3,
sub
#line 1376 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 233
		 'char_type', 1,
sub
#line 1386 "parserxp.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 234
		 'wide_char_type', 1,
sub
#line 1396 "parserxp.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 235
		 'boolean_type', 1,
sub
#line 1406 "parserxp.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 236
		 'octet_type', 1,
sub
#line 1416 "parserxp.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 237
		 'any_type', 1,
sub
#line 1426 "parserxp.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 238
		 'object_type', 1,
sub
#line 1436 "parserxp.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 239
		 'struct_type', 4,
sub
#line 1446 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 240
		 'struct_type', 4,
sub
#line 1453 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 241
		 'struct_header', 3,
sub
#line 1462 "parserxp.yp"
{
			new StructType($_[0],
					'props'				=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 242
		 'struct_header', 3,
sub
#line 1469 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'member_list', 1,
sub
#line 1478 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 244
		 'member_list', 2,
sub
#line 1482 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 245
		 'member', 3,
sub
#line 1491 "parserxp.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 246
		 'union_type', 8,
sub
#line 1502 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 247
		 'union_type', 8,
sub
#line 1510 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 248
		 'union_type', 6,
sub
#line 1516 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 249
		 'union_type', 5,
sub
#line 1522 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 250
		 'union_type', 3,
sub
#line 1528 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 251
		 'union_header', 3,
sub
#line 1537 "parserxp.yp"
{
			new UnionType($_[0],
					'props'				=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 252
		 'union_header', 3,
sub
#line 1544 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 253
		 'switch_type_spec', 1, undef
	],
	[#Rule 254
		 'switch_type_spec', 1, undef
	],
	[#Rule 255
		 'switch_type_spec', 1, undef
	],
	[#Rule 256
		 'switch_type_spec', 1, undef
	],
	[#Rule 257
		 'switch_type_spec', 1,
sub
#line 1561 "parserxp.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 258
		 'switch_body', 1,
sub
#line 1569 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 259
		 'switch_body', 2,
sub
#line 1573 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 260
		 'case', 3,
sub
#line 1582 "parserxp.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 261
		 'case_labels', 1,
sub
#line 1592 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 262
		 'case_labels', 2,
sub
#line 1596 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 263
		 'case_label', 3,
sub
#line 1605 "parserxp.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 264
		 'case_label', 3,
sub
#line 1609 "parserxp.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 265
		 'case_label', 2,
sub
#line 1615 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'case_label', 2,
sub
#line 1620 "parserxp.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 267
		 'case_label', 2,
sub
#line 1624 "parserxp.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 268
		 'element_spec', 2,
sub
#line 1634 "parserxp.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 269
		 'enum_type', 4,
sub
#line 1645 "parserxp.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 270
		 'enum_type', 4,
sub
#line 1651 "parserxp.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 271
		 'enum_type', 2,
sub
#line 1656 "parserxp.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 272
		 'enum_header', 3,
sub
#line 1664 "parserxp.yp"
{
			new EnumType($_[0],
					'props'				=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 273
		 'enum_header', 3,
sub
#line 1671 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 274
		 'enumerators', 1,
sub
#line 1679 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 275
		 'enumerators', 3,
sub
#line 1683 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 276
		 'enumerators', 2,
sub
#line 1688 "parserxp.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 277
		 'enumerators', 2,
sub
#line 1693 "parserxp.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 278
		 'enumerator', 1,
sub
#line 1702 "parserxp.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 279
		 'sequence_type', 6,
sub
#line 1712 "parserxp.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 280
		 'sequence_type', 6,
sub
#line 1720 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 281
		 'sequence_type', 4,
sub
#line 1725 "parserxp.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 282
		 'sequence_type', 4,
sub
#line 1732 "parserxp.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 283
		 'sequence_type', 2,
sub
#line 1737 "parserxp.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 284
		 'string_type', 4,
sub
#line 1746 "parserxp.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 285
		 'string_type', 1,
sub
#line 1753 "parserxp.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 286
		 'string_type', 4,
sub
#line 1759 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 287
		 'wide_string_type', 4,
sub
#line 1768 "parserxp.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 288
		 'wide_string_type', 1,
sub
#line 1775 "parserxp.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 289
		 'wide_string_type', 4,
sub
#line 1781 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 290
		 'array_declarator', 2,
sub
#line 1790 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 291
		 'fixed_array_sizes', 1,
sub
#line 1798 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 292
		 'fixed_array_sizes', 2,
sub
#line 1802 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 293
		 'fixed_array_size', 3,
sub
#line 1811 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 294
		 'fixed_array_size', 3,
sub
#line 1815 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 295
		 'attr_dcl', 1, undef
	],
	[#Rule 296
		 'attr_dcl', 1, undef
	],
	[#Rule 297
		 'except_dcl', 3,
sub
#line 1832 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 298
		 'except_dcl', 4,
sub
#line 1837 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 299
		 'except_dcl', 4,
sub
#line 1844 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 300
		 'except_dcl', 2,
sub
#line 1850 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 301
		 'exception_header', 3,
sub
#line 1859 "parserxp.yp"
{
			new Exception($_[0],
					'declspec'			=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 302
		 'exception_header', 3,
sub
#line 1866 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 303
		 'op_dcl', 4,
sub
#line 1875 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3],
					'list_context'	=>	$_[4]
			) if (defined $_[1]);
		}
	],
	[#Rule 304
		 'op_dcl', 2,
sub
#line 1885 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 305
		 'op_header', 5,
sub
#line 1895 "parserxp.yp"
{
			new Operation($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'modifier'			=>	$_[3],
					'type'				=>	$_[4],
					'idf'				=>	$_[5]
			);
		}
	],
	[#Rule 306
		 'op_header', 5,
sub
#line 1905 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 307
		 'op_mod', 1, undef
	],
	[#Rule 308
		 'op_mod', 0, undef
	],
	[#Rule 309
		 'op_attribute', 1, undef
	],
	[#Rule 310
		 'op_type_spec', 1, undef
	],
	[#Rule 311
		 'op_type_spec', 1,
sub
#line 1929 "parserxp.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 312
		 'op_type_spec', 1,
sub
#line 1935 "parserxp.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 313
		 'op_type_spec', 1,
sub
#line 1940 "parserxp.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 314
		 'parameter_dcls', 3,
sub
#line 1949 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 315
		 'parameter_dcls', 5,
sub
#line 1953 "parserxp.yp"
{
			push(@{$_[2]},new Ellipsis($_[0]));
			$_[2];
		}
	],
	[#Rule 316
		 'parameter_dcls', 4,
sub
#line 1958 "parserxp.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 317
		 'parameter_dcls', 2,
sub
#line 1963 "parserxp.yp"
{
			undef;
		}
	],
	[#Rule 318
		 'parameter_dcls', 3,
sub
#line 1967 "parserxp.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			undef;
		}
	],
	[#Rule 319
		 'parameter_dcls', 3,
sub
#line 1972 "parserxp.yp"
{
			new Ellipsis($_[0]);
		}
	],
	[#Rule 320
		 'param_dcls', 1,
sub
#line 1979 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 321
		 'param_dcls', 3,
sub
#line 1983 "parserxp.yp"
{
			push(@{$_[1]},$_[3]);
			$_[1];
		}
	],
	[#Rule 322
		 'param_dcls', 2,
sub
#line 1988 "parserxp.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 323
		 'param_dcl', 4,
sub
#line 1997 "parserxp.yp"
{
			new Parameter($_[0],
					'props'				=>	$_[1],
					'attr'				=>	$_[2],
					'type'				=>	$_[3],
					'idf'				=>	$_[4]
			);
		}
	],
	[#Rule 324
		 'param_attribute', 1, undef
	],
	[#Rule 325
		 'param_attribute', 1, undef
	],
	[#Rule 326
		 'param_attribute', 1, undef
	],
	[#Rule 327
		 'param_attribute', 0,
sub
#line 2016 "parserxp.yp"
{
			$_[0]->Error("(in|out|inout) expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 328
		 'raises_expr', 4,
sub
#line 2025 "parserxp.yp"
{
			$_[3];
		}
	],
	[#Rule 329
		 'raises_expr', 4,
sub
#line 2029 "parserxp.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 330
		 'raises_expr', 2,
sub
#line 2034 "parserxp.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 331
		 'raises_expr', 0, undef
	],
	[#Rule 332
		 'exception_names', 1,
sub
#line 2044 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 333
		 'exception_names', 3,
sub
#line 2048 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 334
		 'exception_name', 1,
sub
#line 2056 "parserxp.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 335
		 'context_expr', 4,
sub
#line 2064 "parserxp.yp"
{
			$_[3];
		}
	],
	[#Rule 336
		 'context_expr', 4,
sub
#line 2068 "parserxp.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 337
		 'context_expr', 2,
sub
#line 2073 "parserxp.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 338
		 'context_expr', 0, undef
	],
	[#Rule 339
		 'string_literals', 1,
sub
#line 2083 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 340
		 'string_literals', 3,
sub
#line 2087 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 341
		 'param_type_spec', 1, undef
	],
	[#Rule 342
		 'param_type_spec', 1,
sub
#line 2098 "parserxp.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 343
		 'param_type_spec', 1,
sub
#line 2103 "parserxp.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 344
		 'param_type_spec', 1,
sub
#line 2108 "parserxp.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 345
		 'op_param_type_spec', 1, undef
	],
	[#Rule 346
		 'op_param_type_spec', 1, undef
	],
	[#Rule 347
		 'op_param_type_spec', 1, undef
	],
	[#Rule 348
		 'op_param_type_spec', 1,
sub
#line 2122 "parserxp.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 349
		 'fixed_pt_type', 6,
sub
#line 2130 "parserxp.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 350
		 'fixed_pt_type', 6,
sub
#line 2138 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 351
		 'fixed_pt_type', 4,
sub
#line 2143 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 352
		 'fixed_pt_type', 2,
sub
#line 2148 "parserxp.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 353
		 'fixed_pt_const_type', 1,
sub
#line 2157 "parserxp.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 354
		 'value_base_type', 1,
sub
#line 2167 "parserxp.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 355
		 'constr_forward_decl', 3,
sub
#line 2177 "parserxp.yp"
{
			$_[0]->Warning("Ignoring properties for forward declaration.\n")
					if (defined $_[1]);
			new ForwardStructType($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 356
		 'constr_forward_decl', 3,
sub
#line 2185 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 357
		 'constr_forward_decl', 3,
sub
#line 2190 "parserxp.yp"
{
			$_[0]->Warning("Ignoring properties for forward declaration.\n")
					if (defined $_[1]);
			new ForwardUnionType($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 358
		 'constr_forward_decl', 3,
sub
#line 2198 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 359
		 'import', 3,
sub
#line 2207 "parserxp.yp"
{
			new Import($_[0],
					'value'				=>	$_[2]
			);
		}
	],
	[#Rule 360
		 'import', 2,
sub
#line 2213 "parserxp.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 361
		 'imported_scope', 1, undef
	],
	[#Rule 362
		 'imported_scope', 1, undef
	],
	[#Rule 363
		 'type_id_dcl', 3,
sub
#line 2230 "parserxp.yp"
{
			new TypeId($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 364
		 'type_id_dcl', 3,
sub
#line 2237 "parserxp.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 365
		 'type_id_dcl', 2,
sub
#line 2242 "parserxp.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 366
		 'type_prefix_dcl', 3,
sub
#line 2251 "parserxp.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 367
		 'type_prefix_dcl', 3,
sub
#line 2258 "parserxp.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 368
		 'type_prefix_dcl', 3,
sub
#line 2263 "parserxp.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	'',
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 369
		 'type_prefix_dcl', 2,
sub
#line 2270 "parserxp.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 370
		 'readonly_attr_spec', 6,
sub
#line 2279 "parserxp.yp"
{
			new Attributes($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'modifier'			=>	$_[3],
					'type'				=>	$_[5],
					'list_expr'			=>	$_[6]->{list_expr},
					'list_getraise'		=>	$_[6]->{list_getraise},
			);
		}
	],
	[#Rule 371
		 'readonly_attr_spec', 5,
sub
#line 2290 "parserxp.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 372
		 'readonly_attr_spec', 4,
sub
#line 2295 "parserxp.yp"
{
			$_[0]->Error("'attribute' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 373
		 'readonly_attr_declarator', 2,
sub
#line 2304 "parserxp.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]
			};
		}
	],
	[#Rule 374
		 'readonly_attr_declarator', 3,
sub
#line 2311 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			{
				'list_expr'			=> $_[3]
			};
		}
	],
	[#Rule 375
		 'simple_declarators', 1,
sub
#line 2321 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 376
		 'simple_declarators', 3,
sub
#line 2325 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 377
		 'attr_spec', 5,
sub
#line 2334 "parserxp.yp"
{
			new Attributes($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[5]->{list_expr},
					'list_getraise'		=>	$_[5]->{list_getraise},
					'list_setraise'		=>	$_[5]->{list_setraise},
			);
		}
	],
	[#Rule 378
		 'attr_spec', 4,
sub
#line 2345 "parserxp.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 379
		 'attr_declarator', 2,
sub
#line 2354 "parserxp.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]->{list_getraise},
				'list_setraise'		=> $_[2]->{list_setraise}
			};
		}
	],
	[#Rule 380
		 'attr_declarator', 3,
sub
#line 2362 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			{
				'list_expr'			=> $_[3]
			};
		}
	],
	[#Rule 381
		 'attr_raises_expr', 2,
sub
#line 2373 "parserxp.yp"
{
			{
				'list_getraise'		=> $_[1],
				'list_setraise'		=> $_[2]
			};
		}
	],
	[#Rule 382
		 'attr_raises_expr', 1,
sub
#line 2380 "parserxp.yp"
{
			{
				'list_getraise'		=> $_[1],
			};
		}
	],
	[#Rule 383
		 'attr_raises_expr', 1,
sub
#line 2386 "parserxp.yp"
{
			{
				'list_setraise'		=> $_[1]
			};
		}
	],
	[#Rule 384
		 'attr_raises_expr', 0, undef
	],
	[#Rule 385
		 'get_except_expr', 2,
sub
#line 2398 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 386
		 'get_except_expr', 2,
sub
#line 2402 "parserxp.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 387
		 'set_except_expr', 2,
sub
#line 2411 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 388
		 'set_except_expr', 2,
sub
#line 2415 "parserxp.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 389
		 'exception_list', 3,
sub
#line 2424 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 390
		 'exception_list', 3,
sub
#line 2428 "parserxp.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 391
		 'code_frag', 2,
sub
#line 2438 "parserxp.yp"
{
			new CodeFragment($_[0],
					'declspec'			=>	$_[1],
					'value'				=>	$_[2],
			);
		}
	],
	[#Rule 392
		 'declspec', 0, undef
	],
	[#Rule 393
		 'declspec', 1, undef
	],
	[#Rule 394
		 'props', 0, undef
	],
	[#Rule 395
		 '@2-1', 0,
sub
#line 2457 "parserxp.yp"
{
			$_[0]->YYData->{prop} = 1;
		}
	],
	[#Rule 396
		 'props', 4,
sub
#line 2461 "parserxp.yp"
{
			$_[0]->YYData->{prop} = 0;
			$_[3];
		}
	],
	[#Rule 397
		 'prop_list', 2,
sub
#line 2469 "parserxp.yp"
{
			my $hash = {};
			$hash->{$_[1]} = $_[2];
			$hash;
		}
	],
	[#Rule 398
		 'prop_list', 4,
sub
#line 2475 "parserxp.yp"
{
			$_[1]->{$_[3]} = $_[4];
			$_[1];
		}
	],
	[#Rule 399
		 'prop_list', 1,
sub
#line 2480 "parserxp.yp"
{
			my $hash = {};
			$hash->{$_[1]} = undef;
			$hash;
		}
	],
	[#Rule 400
		 'prop_list', 3,
sub
#line 2486 "parserxp.yp"
{
			$_[1]->{$_[3]} = undef;
			$_[1];
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 2492 "parserxp.yp"


package Parser;

use strict;
use vars qw($IDL_version);
$IDL_version = '3.0';

use CORBA::IDL::symbtab;
use CORBA::IDL::node;

require CORBA::IDL::lexer;

sub BuildUnop
{
	my($op,$expr) = @_;

	my $node = new UnaryOp($_[0],	'op'	=>	$op);
	push(@$expr,$node);
	return $expr;
}

sub BuildBinop
{
	my($left,$op,$right) = @_;

	my $node = new BinaryOp($_[0],	'op'	=>	$op);
	push(@$left,@$right);
	push(@$left,$node);
	return $left;
}


1;
