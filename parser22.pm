####################################################################
#
#    This file was generated using Parse::Yapp version 1.02.
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
# (c) Copyright 1998-1999 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.02';
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

    my($self)=$class->SUPER::new( yyversion => '1.02',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'' => -2,
			'TYPEDEF' => 12,
			'MODULE' => 14,
			'NATIVE' => 2,
			'UNION' => 16,
			'STRUCT' => 6,
			'error' => 19,
			'CONST' => 22,
			'EXCEPTION' => 23,
			'ENUM' => 28,
			'INTERFACE' => 29
		},
		GOTOS => {
			'const_dcl' => 1,
			'except_dcl' => 4,
			'interface_header' => 3,
			'specification' => 5,
			'module_header' => 7,
			'interface' => 8,
			'struct_type' => 9,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'interface_dcl' => 15,
			'enum_type' => 17,
			'forward_dcl' => 18,
			'module' => 21,
			'enum_header' => 20,
			'union_header' => 24,
			'type_dcl' => 25,
			'definitions' => 26,
			'definition' => 27
		}
	},
	{#State 1
		ACTIONS => {
			'error' => 31,
			";" => 30
		}
	},
	{#State 2
		ACTIONS => {
			'error' => 34,
			'IDENTIFIER' => 33
		},
		GOTOS => {
			'simple_declarator' => 32
		}
	},
	{#State 3
		ACTIONS => {
			"{" => 35
		}
	},
	{#State 4
		ACTIONS => {
			'error' => 37,
			";" => 36
		}
	},
	{#State 5
		ACTIONS => {
			'' => 38
		}
	},
	{#State 6
		ACTIONS => {
			'IDENTIFIER' => 39
		}
	},
	{#State 7
		ACTIONS => {
			"{" => 41,
			'error' => 40
		}
	},
	{#State 8
		ACTIONS => {
			'error' => 43,
			";" => 42
		}
	},
	{#State 9
		DEFAULT => -109
	},
	{#State 10
		ACTIONS => {
			"{" => 45,
			'error' => 44
		}
	},
	{#State 11
		DEFAULT => -110
	},
	{#State 12
		ACTIONS => {
			'CHAR' => 73,
			'OBJECT' => 74,
			'FIXED' => 48,
			'SEQUENCE' => 50,
			'STRUCT' => 6,
			'DOUBLE' => 78,
			'LONG' => 79,
			'STRING' => 80,
			"::" => 81,
			'WSTRING' => 83,
			'UNSIGNED' => 59,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'IDENTIFIER' => 87,
			'UNION' => 16,
			'WCHAR' => 62,
			'error' => 67,
			'FLOAT' => 70,
			'OCTET' => 68,
			'ENUM' => 28,
			'ANY' => 72
		},
		GOTOS => {
			'unsigned_int' => 46,
			'floating_pt_type' => 47,
			'signed_int' => 49,
			'char_type' => 51,
			'object_type' => 52,
			'octet_type' => 53,
			'scoped_name' => 54,
			'wide_char_type' => 55,
			'type_spec' => 57,
			'signed_long_int' => 56,
			'type_declarator' => 58,
			'string_type' => 60,
			'struct_header' => 13,
			'unsigned_longlong_int' => 63,
			'any_type' => 64,
			'base_type_spec' => 65,
			'enum_type' => 66,
			'enum_header' => 20,
			'union_header' => 24,
			'unsigned_short_int' => 69,
			'signed_longlong_int' => 71,
			'wide_string_type' => 75,
			'integer_type' => 76,
			'boolean_type' => 77,
			'signed_short_int' => 82,
			'struct_type' => 84,
			'union_type' => 86,
			'sequence_type' => 88,
			'unsigned_long_int' => 89,
			'template_type_spec' => 90,
			'constr_type_spec' => 91,
			'simple_type_spec' => 92,
			'fixed_pt_type' => 93
		}
	},
	{#State 13
		ACTIONS => {
			"{" => 94
		}
	},
	{#State 14
		ACTIONS => {
			'error' => 95,
			'IDENTIFIER' => 96
		}
	},
	{#State 15
		DEFAULT => -21
	},
	{#State 16
		ACTIONS => {
			'IDENTIFIER' => 97
		}
	},
	{#State 17
		DEFAULT => -111
	},
	{#State 18
		DEFAULT => -22
	},
	{#State 19
		DEFAULT => -3
	},
	{#State 20
		ACTIONS => {
			"{" => 99,
			'error' => 98
		}
	},
	{#State 21
		ACTIONS => {
			'error' => 101,
			";" => 100
		}
	},
	{#State 22
		ACTIONS => {
			'CHAR' => 73,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'IDENTIFIER' => 87,
			'FIXED' => 103,
			'WCHAR' => 62,
			'DOUBLE' => 78,
			'error' => 108,
			'LONG' => 79,
			'STRING' => 80,
			"::" => 81,
			'FLOAT' => 70,
			'WSTRING' => 83,
			'UNSIGNED' => 59
		},
		GOTOS => {
			'unsigned_int' => 46,
			'floating_pt_type' => 102,
			'signed_int' => 49,
			'wide_string_type' => 109,
			'integer_type' => 111,
			'boolean_type' => 110,
			'char_type' => 104,
			'scoped_name' => 105,
			'fixed_pt_const_type' => 112,
			'wide_char_type' => 106,
			'signed_long_int' => 56,
			'signed_short_int' => 82,
			'const_type' => 113,
			'string_type' => 107,
			'unsigned_longlong_int' => 63,
			'unsigned_long_int' => 89,
			'unsigned_short_int' => 69,
			'signed_longlong_int' => 71
		}
	},
	{#State 23
		ACTIONS => {
			'error' => 114,
			'IDENTIFIER' => 115
		}
	},
	{#State 24
		ACTIONS => {
			'SWITCH' => 116
		}
	},
	{#State 25
		ACTIONS => {
			'error' => 118,
			";" => 117
		}
	},
	{#State 26
		DEFAULT => -1
	},
	{#State 27
		ACTIONS => {
			'TYPEDEF' => 12,
			'NATIVE' => 2,
			'MODULE' => 14,
			'UNION' => 16,
			'STRUCT' => 6,
			'CONST' => 22,
			'EXCEPTION' => 23,
			'ENUM' => 28,
			'INTERFACE' => 29
		},
		DEFAULT => -4,
		GOTOS => {
			'const_dcl' => 1,
			'interface_header' => 3,
			'except_dcl' => 4,
			'module_header' => 7,
			'interface' => 8,
			'struct_type' => 9,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'interface_dcl' => 15,
			'enum_type' => 17,
			'forward_dcl' => 18,
			'enum_header' => 20,
			'module' => 21,
			'union_header' => 24,
			'definitions' => 119,
			'type_dcl' => 25,
			'definition' => 27
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 120,
			'IDENTIFIER' => 121
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 122,
			'IDENTIFIER' => 123
		}
	},
	{#State 30
		DEFAULT => -7
	},
	{#State 31
		DEFAULT => -12
	},
	{#State 32
		DEFAULT => -112
	},
	{#State 33
		DEFAULT => -141
	},
	{#State 34
		DEFAULT => -114
	},
	{#State 35
		ACTIONS => {
			'CHAR' => -243,
			'OBJECT' => -243,
			'ONEWAY' => 124,
			'FIXED' => -243,
			'NATIVE' => 2,
			'VOID' => -243,
			'STRUCT' => 6,
			'DOUBLE' => -243,
			'LONG' => -243,
			'STRING' => -243,
			"::" => -243,
			'WSTRING' => -243,
			'UNSIGNED' => -243,
			'SHORT' => -243,
			'TYPEDEF' => 12,
			'BOOLEAN' => -243,
			'IDENTIFIER' => -243,
			'UNION' => 16,
			'READONLY' => 135,
			'WCHAR' => -243,
			'ATTRIBUTE' => -226,
			'error' => 129,
			'CONST' => 22,
			"}" => 130,
			'EXCEPTION' => 23,
			'OCTET' => -243,
			'FLOAT' => -243,
			'ENUM' => 28,
			'ANY' => -243
		},
		GOTOS => {
			'const_dcl' => 131,
			'op_mod' => 125,
			'except_dcl' => 126,
			'op_attribute' => 127,
			'attr_mod' => 128,
			'exports' => 132,
			'export' => 133,
			'struct_type' => 9,
			'op_header' => 134,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'enum_type' => 17,
			'op_dcl' => 136,
			'enum_header' => 20,
			'attr_dcl' => 137,
			'type_dcl' => 138,
			'union_header' => 24,
			'interface_body' => 139
		}
	},
	{#State 36
		DEFAULT => -8
	},
	{#State 37
		DEFAULT => -13
	},
	{#State 38
		DEFAULT => 0
	},
	{#State 39
		DEFAULT => -168
	},
	{#State 40
		DEFAULT => -18
	},
	{#State 41
		ACTIONS => {
			'TYPEDEF' => 12,
			'NATIVE' => 2,
			'MODULE' => 14,
			'UNION' => 16,
			'STRUCT' => 6,
			'error' => 140,
			'CONST' => 22,
			'EXCEPTION' => 23,
			'ENUM' => 28,
			'INTERFACE' => 29
		},
		GOTOS => {
			'const_dcl' => 1,
			'interface_header' => 3,
			'except_dcl' => 4,
			'module_header' => 7,
			'interface' => 8,
			'struct_type' => 9,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'interface_dcl' => 15,
			'enum_type' => 17,
			'forward_dcl' => 18,
			'enum_header' => 20,
			'module' => 21,
			'union_header' => 24,
			'definitions' => 141,
			'type_dcl' => 25,
			'definition' => 27
		}
	},
	{#State 42
		DEFAULT => -9
	},
	{#State 43
		DEFAULT => -14
	},
	{#State 44
		DEFAULT => -232
	},
	{#State 45
		ACTIONS => {
			'CHAR' => 73,
			'OBJECT' => 74,
			'FIXED' => 48,
			'SEQUENCE' => 50,
			'STRUCT' => 6,
			'DOUBLE' => 78,
			'LONG' => 79,
			'STRING' => 80,
			"::" => 81,
			'WSTRING' => 83,
			'UNSIGNED' => 59,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'IDENTIFIER' => 87,
			'UNION' => 16,
			'WCHAR' => 62,
			'error' => 143,
			"}" => 145,
			'FLOAT' => 70,
			'OCTET' => 68,
			'ENUM' => 28,
			'ANY' => 72
		},
		GOTOS => {
			'unsigned_int' => 46,
			'floating_pt_type' => 47,
			'signed_int' => 49,
			'char_type' => 51,
			'object_type' => 52,
			'octet_type' => 53,
			'scoped_name' => 54,
			'wide_char_type' => 55,
			'signed_long_int' => 56,
			'type_spec' => 142,
			'string_type' => 60,
			'struct_header' => 13,
			'unsigned_longlong_int' => 63,
			'any_type' => 64,
			'base_type_spec' => 65,
			'enum_type' => 66,
			'enum_header' => 20,
			'member_list' => 144,
			'union_header' => 24,
			'unsigned_short_int' => 69,
			'signed_longlong_int' => 71,
			'wide_string_type' => 75,
			'boolean_type' => 77,
			'integer_type' => 76,
			'signed_short_int' => 82,
			'member' => 146,
			'struct_type' => 84,
			'union_type' => 86,
			'sequence_type' => 88,
			'unsigned_long_int' => 89,
			'template_type_spec' => 90,
			'constr_type_spec' => 91,
			'simple_type_spec' => 92,
			'fixed_pt_type' => 93
		}
	},
	{#State 46
		DEFAULT => -147
	},
	{#State 47
		DEFAULT => -122
	},
	{#State 48
		ACTIONS => {
			"<" => 148,
			'error' => 147
		}
	},
	{#State 49
		DEFAULT => -146
	},
	{#State 50
		ACTIONS => {
			"<" => 150,
			'error' => 149
		}
	},
	{#State 51
		DEFAULT => -124
	},
	{#State 52
		DEFAULT => -129
	},
	{#State 53
		DEFAULT => -127
	},
	{#State 54
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -121
	},
	{#State 55
		DEFAULT => -125
	},
	{#State 56
		DEFAULT => -149
	},
	{#State 57
		ACTIONS => {
			'error' => 154,
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'declarators' => 152,
			'declarator' => 153,
			'simple_declarator' => 156,
			'array_declarator' => 157,
			'complex_declarator' => 155
		}
	},
	{#State 58
		DEFAULT => -108
	},
	{#State 59
		ACTIONS => {
			'SHORT' => 159,
			'LONG' => 160
		}
	},
	{#State 60
		DEFAULT => -131
	},
	{#State 61
		DEFAULT => -151
	},
	{#State 62
		DEFAULT => -161
	},
	{#State 63
		DEFAULT => -156
	},
	{#State 64
		DEFAULT => -128
	},
	{#State 65
		DEFAULT => -119
	},
	{#State 66
		DEFAULT => -136
	},
	{#State 67
		DEFAULT => -113
	},
	{#State 68
		DEFAULT => -163
	},
	{#State 69
		DEFAULT => -154
	},
	{#State 70
		DEFAULT => -143
	},
	{#State 71
		DEFAULT => -150
	},
	{#State 72
		DEFAULT => -164
	},
	{#State 73
		DEFAULT => -160
	},
	{#State 74
		DEFAULT => -165
	},
	{#State 75
		DEFAULT => -132
	},
	{#State 76
		DEFAULT => -123
	},
	{#State 77
		DEFAULT => -126
	},
	{#State 78
		DEFAULT => -144
	},
	{#State 79
		ACTIONS => {
			'LONG' => 162,
			'DOUBLE' => 161
		},
		DEFAULT => -152
	},
	{#State 80
		ACTIONS => {
			"<" => 163
		},
		DEFAULT => -212
	},
	{#State 81
		ACTIONS => {
			'error' => 164,
			'IDENTIFIER' => 165
		}
	},
	{#State 82
		DEFAULT => -148
	},
	{#State 83
		ACTIONS => {
			"<" => 166
		},
		DEFAULT => -215
	},
	{#State 84
		DEFAULT => -134
	},
	{#State 85
		DEFAULT => -162
	},
	{#State 86
		DEFAULT => -135
	},
	{#State 87
		DEFAULT => -48
	},
	{#State 88
		DEFAULT => -130
	},
	{#State 89
		DEFAULT => -155
	},
	{#State 90
		DEFAULT => -120
	},
	{#State 91
		DEFAULT => -118
	},
	{#State 92
		DEFAULT => -117
	},
	{#State 93
		DEFAULT => -133
	},
	{#State 94
		ACTIONS => {
			'CHAR' => 73,
			'OBJECT' => 74,
			'FIXED' => 48,
			'SEQUENCE' => 50,
			'STRUCT' => 6,
			'DOUBLE' => 78,
			'LONG' => 79,
			'STRING' => 80,
			"::" => 81,
			'WSTRING' => 83,
			'UNSIGNED' => 59,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'IDENTIFIER' => 87,
			'UNION' => 16,
			'WCHAR' => 62,
			'error' => 167,
			'FLOAT' => 70,
			'OCTET' => 68,
			'ENUM' => 28,
			'ANY' => 72
		},
		GOTOS => {
			'unsigned_int' => 46,
			'floating_pt_type' => 47,
			'signed_int' => 49,
			'char_type' => 51,
			'object_type' => 52,
			'octet_type' => 53,
			'scoped_name' => 54,
			'wide_char_type' => 55,
			'signed_long_int' => 56,
			'type_spec' => 142,
			'string_type' => 60,
			'struct_header' => 13,
			'unsigned_longlong_int' => 63,
			'any_type' => 64,
			'base_type_spec' => 65,
			'enum_type' => 66,
			'enum_header' => 20,
			'member_list' => 168,
			'union_header' => 24,
			'unsigned_short_int' => 69,
			'signed_longlong_int' => 71,
			'wide_string_type' => 75,
			'boolean_type' => 77,
			'integer_type' => 76,
			'signed_short_int' => 82,
			'member' => 146,
			'struct_type' => 84,
			'union_type' => 86,
			'sequence_type' => 88,
			'unsigned_long_int' => 89,
			'template_type_spec' => 90,
			'constr_type_spec' => 91,
			'simple_type_spec' => 92,
			'fixed_pt_type' => 93
		}
	},
	{#State 95
		DEFAULT => -20
	},
	{#State 96
		DEFAULT => -19
	},
	{#State 97
		DEFAULT => -178
	},
	{#State 98
		DEFAULT => -198
	},
	{#State 99
		ACTIONS => {
			'error' => 169,
			'IDENTIFIER' => 171
		},
		GOTOS => {
			'enumerators' => 172,
			'enumerator' => 170
		}
	},
	{#State 100
		DEFAULT => -10
	},
	{#State 101
		DEFAULT => -15
	},
	{#State 102
		DEFAULT => -62
	},
	{#State 103
		DEFAULT => -278
	},
	{#State 104
		DEFAULT => -59
	},
	{#State 105
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -66
	},
	{#State 106
		DEFAULT => -60
	},
	{#State 107
		DEFAULT => -63
	},
	{#State 108
		DEFAULT => -57
	},
	{#State 109
		DEFAULT => -64
	},
	{#State 110
		DEFAULT => -61
	},
	{#State 111
		DEFAULT => -58
	},
	{#State 112
		DEFAULT => -65
	},
	{#State 113
		ACTIONS => {
			'error' => 173,
			'IDENTIFIER' => 174
		}
	},
	{#State 114
		DEFAULT => -234
	},
	{#State 115
		DEFAULT => -233
	},
	{#State 116
		ACTIONS => {
			'error' => 176,
			"(" => 175
		}
	},
	{#State 117
		DEFAULT => -6
	},
	{#State 118
		DEFAULT => -11
	},
	{#State 119
		DEFAULT => -5
	},
	{#State 120
		DEFAULT => -200
	},
	{#State 121
		DEFAULT => -199
	},
	{#State 122
		DEFAULT => -27
	},
	{#State 123
		ACTIONS => {
			"{" => -28,
			":" => 177
		},
		DEFAULT => -26,
		GOTOS => {
			'interface_inheritance_spec' => 178
		}
	},
	{#State 124
		DEFAULT => -244
	},
	{#State 125
		ACTIONS => {
			'CHAR' => 73,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'OBJECT' => 74,
			'IDENTIFIER' => 87,
			'FIXED' => 48,
			'VOID' => 184,
			'WCHAR' => 62,
			'DOUBLE' => 78,
			'LONG' => 79,
			'STRING' => 80,
			"::" => 81,
			'OCTET' => 68,
			'FLOAT' => 70,
			'WSTRING' => 83,
			'UNSIGNED' => 59,
			'ANY' => 72
		},
		GOTOS => {
			'unsigned_int' => 46,
			'floating_pt_type' => 47,
			'signed_int' => 49,
			'wide_string_type' => 183,
			'integer_type' => 76,
			'boolean_type' => 77,
			'char_type' => 51,
			'object_type' => 52,
			'octet_type' => 53,
			'scoped_name' => 179,
			'wide_char_type' => 55,
			'signed_long_int' => 56,
			'signed_short_int' => 82,
			'string_type' => 180,
			'op_type_spec' => 185,
			'base_type_spec' => 181,
			'unsigned_longlong_int' => 63,
			'any_type' => 64,
			'unsigned_long_int' => 89,
			'param_type_spec' => 182,
			'unsigned_short_int' => 69,
			'fixed_pt_type' => 186,
			'signed_longlong_int' => 71
		}
	},
	{#State 126
		ACTIONS => {
			'error' => 188,
			";" => 187
		}
	},
	{#State 127
		DEFAULT => -242
	},
	{#State 128
		ACTIONS => {
			'ATTRIBUTE' => 189
		}
	},
	{#State 129
		ACTIONS => {
			"}" => 190
		}
	},
	{#State 130
		DEFAULT => -23
	},
	{#State 131
		ACTIONS => {
			'error' => 192,
			";" => 191
		}
	},
	{#State 132
		DEFAULT => -30
	},
	{#State 133
		ACTIONS => {
			'ONEWAY' => 124,
			'NATIVE' => 2,
			'STRUCT' => 6,
			'TYPEDEF' => 12,
			'UNION' => 16,
			'READONLY' => 135,
			'ATTRIBUTE' => -226,
			'CONST' => 22,
			"}" => -31,
			'EXCEPTION' => 23,
			'ENUM' => 28
		},
		DEFAULT => -243,
		GOTOS => {
			'const_dcl' => 131,
			'op_mod' => 125,
			'except_dcl' => 126,
			'op_attribute' => 127,
			'attr_mod' => 128,
			'exports' => 193,
			'export' => 133,
			'struct_type' => 9,
			'op_header' => 134,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'enum_type' => 17,
			'op_dcl' => 136,
			'enum_header' => 20,
			'attr_dcl' => 137,
			'type_dcl' => 138,
			'union_header' => 24
		}
	},
	{#State 134
		ACTIONS => {
			'error' => 195,
			"(" => 194
		},
		GOTOS => {
			'parameter_dcls' => 196
		}
	},
	{#State 135
		DEFAULT => -225
	},
	{#State 136
		ACTIONS => {
			'error' => 198,
			";" => 197
		}
	},
	{#State 137
		ACTIONS => {
			'error' => 200,
			";" => 199
		}
	},
	{#State 138
		ACTIONS => {
			'error' => 202,
			";" => 201
		}
	},
	{#State 139
		ACTIONS => {
			"}" => 203
		}
	},
	{#State 140
		ACTIONS => {
			"}" => 204
		}
	},
	{#State 141
		ACTIONS => {
			"}" => 205
		}
	},
	{#State 142
		ACTIONS => {
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'declarators' => 206,
			'declarator' => 153,
			'simple_declarator' => 156,
			'array_declarator' => 157,
			'complex_declarator' => 155
		}
	},
	{#State 143
		ACTIONS => {
			"}" => 207
		}
	},
	{#State 144
		ACTIONS => {
			"}" => 208
		}
	},
	{#State 145
		DEFAULT => -229
	},
	{#State 146
		ACTIONS => {
			'CHAR' => 73,
			'OBJECT' => 74,
			'FIXED' => 48,
			'SEQUENCE' => 50,
			'STRUCT' => 6,
			'DOUBLE' => 78,
			'LONG' => 79,
			'STRING' => 80,
			"::" => 81,
			'WSTRING' => 83,
			'UNSIGNED' => 59,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'IDENTIFIER' => 87,
			'UNION' => 16,
			'WCHAR' => 62,
			'FLOAT' => 70,
			'OCTET' => 68,
			'ENUM' => 28,
			'ANY' => 72
		},
		DEFAULT => -169,
		GOTOS => {
			'unsigned_int' => 46,
			'floating_pt_type' => 47,
			'signed_int' => 49,
			'char_type' => 51,
			'object_type' => 52,
			'octet_type' => 53,
			'scoped_name' => 54,
			'wide_char_type' => 55,
			'signed_long_int' => 56,
			'type_spec' => 142,
			'string_type' => 60,
			'struct_header' => 13,
			'unsigned_longlong_int' => 63,
			'any_type' => 64,
			'base_type_spec' => 65,
			'enum_type' => 66,
			'enum_header' => 20,
			'member_list' => 209,
			'union_header' => 24,
			'unsigned_short_int' => 69,
			'signed_longlong_int' => 71,
			'wide_string_type' => 75,
			'boolean_type' => 77,
			'integer_type' => 76,
			'signed_short_int' => 82,
			'member' => 146,
			'struct_type' => 84,
			'union_type' => 86,
			'sequence_type' => 88,
			'unsigned_long_int' => 89,
			'template_type_spec' => 90,
			'constr_type_spec' => 91,
			'simple_type_spec' => 92,
			'fixed_pt_type' => 93
		}
	},
	{#State 147
		DEFAULT => -277
	},
	{#State 148
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'CHARACTER_LITERAL' => 210,
			'WIDE_CHARACTER_LITERAL' => 211,
			"::" => 81,
			'INTEGER_LITERAL' => 231,
			"(" => 215,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'FIXED_PT_LITERAL' => 234,
			"+" => 235,
			'error' => 219,
			"-" => 237,
			'WIDE_STRING_LITERAL' => 223,
			'FALSE' => 222,
			"~" => 238,
			'TRUE' => 225
		},
		GOTOS => {
			'string_literal' => 227,
			'primary_expr' => 229,
			'and_expr' => 230,
			'scoped_name' => 212,
			'positive_int_const' => 213,
			'wide_string_literal' => 214,
			'boolean_literal' => 216,
			'mult_expr' => 232,
			'const_exp' => 217,
			'or_expr' => 218,
			'unary_expr' => 236,
			'xor_expr' => 220,
			'shift_expr' => 221,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 149
		DEFAULT => -210
	},
	{#State 150
		ACTIONS => {
			'CHAR' => 73,
			'OBJECT' => 74,
			'FIXED' => 48,
			'SEQUENCE' => 50,
			'DOUBLE' => 78,
			'LONG' => 79,
			'STRING' => 80,
			"::" => 81,
			'WSTRING' => 83,
			'UNSIGNED' => 59,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'IDENTIFIER' => 87,
			'WCHAR' => 62,
			'error' => 240,
			'FLOAT' => 70,
			'OCTET' => 68,
			'ANY' => 72
		},
		GOTOS => {
			'unsigned_int' => 46,
			'floating_pt_type' => 47,
			'signed_int' => 49,
			'wide_string_type' => 75,
			'integer_type' => 76,
			'boolean_type' => 77,
			'char_type' => 51,
			'object_type' => 52,
			'octet_type' => 53,
			'scoped_name' => 54,
			'wide_char_type' => 55,
			'signed_long_int' => 56,
			'signed_short_int' => 82,
			'string_type' => 60,
			'sequence_type' => 88,
			'unsigned_longlong_int' => 63,
			'any_type' => 64,
			'base_type_spec' => 65,
			'unsigned_long_int' => 89,
			'template_type_spec' => 90,
			'unsigned_short_int' => 69,
			'simple_type_spec' => 241,
			'fixed_pt_type' => 93,
			'signed_longlong_int' => 71
		}
	},
	{#State 151
		ACTIONS => {
			'error' => 242,
			'IDENTIFIER' => 243
		}
	},
	{#State 152
		DEFAULT => -115
	},
	{#State 153
		ACTIONS => {
			"," => 244
		},
		DEFAULT => -137
	},
	{#State 154
		DEFAULT => -116
	},
	{#State 155
		DEFAULT => -140
	},
	{#State 156
		DEFAULT => -139
	},
	{#State 157
		DEFAULT => -142
	},
	{#State 158
		ACTIONS => {
			"[" => 247
		},
		DEFAULT => -141,
		GOTOS => {
			'fixed_array_sizes' => 245,
			'fixed_array_size' => 246
		}
	},
	{#State 159
		DEFAULT => -157
	},
	{#State 160
		ACTIONS => {
			'LONG' => 248
		},
		DEFAULT => -158
	},
	{#State 161
		DEFAULT => -145
	},
	{#State 162
		DEFAULT => -153
	},
	{#State 163
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'CHARACTER_LITERAL' => 210,
			'WIDE_CHARACTER_LITERAL' => 211,
			"::" => 81,
			'INTEGER_LITERAL' => 231,
			"(" => 215,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'FIXED_PT_LITERAL' => 234,
			"+" => 235,
			'error' => 250,
			"-" => 237,
			'WIDE_STRING_LITERAL' => 223,
			'FALSE' => 222,
			"~" => 238,
			'TRUE' => 225
		},
		GOTOS => {
			'string_literal' => 227,
			'primary_expr' => 229,
			'and_expr' => 230,
			'scoped_name' => 212,
			'positive_int_const' => 249,
			'wide_string_literal' => 214,
			'boolean_literal' => 216,
			'mult_expr' => 232,
			'const_exp' => 217,
			'or_expr' => 218,
			'unary_expr' => 236,
			'xor_expr' => 220,
			'shift_expr' => 221,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 164
		DEFAULT => -50
	},
	{#State 165
		DEFAULT => -49
	},
	{#State 166
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'CHARACTER_LITERAL' => 210,
			'WIDE_CHARACTER_LITERAL' => 211,
			"::" => 81,
			'INTEGER_LITERAL' => 231,
			"(" => 215,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'FIXED_PT_LITERAL' => 234,
			"+" => 235,
			'error' => 252,
			"-" => 237,
			'WIDE_STRING_LITERAL' => 223,
			'FALSE' => 222,
			"~" => 238,
			'TRUE' => 225
		},
		GOTOS => {
			'string_literal' => 227,
			'primary_expr' => 229,
			'and_expr' => 230,
			'scoped_name' => 212,
			'positive_int_const' => 251,
			'wide_string_literal' => 214,
			'boolean_literal' => 216,
			'mult_expr' => 232,
			'const_exp' => 217,
			'or_expr' => 218,
			'unary_expr' => 236,
			'xor_expr' => 220,
			'shift_expr' => 221,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 167
		ACTIONS => {
			"}" => 253
		}
	},
	{#State 168
		ACTIONS => {
			"}" => 254
		}
	},
	{#State 169
		ACTIONS => {
			"}" => 255
		}
	},
	{#State 170
		ACTIONS => {
			";" => 256,
			"," => 257
		},
		DEFAULT => -201
	},
	{#State 171
		DEFAULT => -205
	},
	{#State 172
		ACTIONS => {
			"}" => 258
		}
	},
	{#State 173
		DEFAULT => -56
	},
	{#State 174
		ACTIONS => {
			'error' => 259,
			"=" => 260
		}
	},
	{#State 175
		ACTIONS => {
			'CHAR' => 73,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'IDENTIFIER' => 87,
			'error' => 264,
			'LONG' => 268,
			"::" => 81,
			'ENUM' => 28,
			'UNSIGNED' => 59
		},
		GOTOS => {
			'switch_type_spec' => 265,
			'unsigned_int' => 46,
			'signed_int' => 49,
			'integer_type' => 267,
			'boolean_type' => 266,
			'unsigned_longlong_int' => 63,
			'char_type' => 261,
			'enum_type' => 263,
			'unsigned_long_int' => 89,
			'scoped_name' => 262,
			'enum_header' => 20,
			'signed_long_int' => 56,
			'unsigned_short_int' => 69,
			'signed_short_int' => 82,
			'signed_longlong_int' => 71
		}
	},
	{#State 176
		DEFAULT => -177
	},
	{#State 177
		ACTIONS => {
			'error' => 270,
			'IDENTIFIER' => 87,
			"::" => 81
		},
		GOTOS => {
			'scoped_name' => 269,
			'interface_names' => 272,
			'interface_name' => 271
		}
	},
	{#State 178
		DEFAULT => -29
	},
	{#State 179
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -273
	},
	{#State 180
		DEFAULT => -270
	},
	{#State 181
		DEFAULT => -269
	},
	{#State 182
		DEFAULT => -245
	},
	{#State 183
		DEFAULT => -271
	},
	{#State 184
		DEFAULT => -246
	},
	{#State 185
		ACTIONS => {
			'error' => 273,
			'IDENTIFIER' => 274
		}
	},
	{#State 186
		DEFAULT => -272
	},
	{#State 187
		DEFAULT => -35
	},
	{#State 188
		DEFAULT => -40
	},
	{#State 189
		ACTIONS => {
			'CHAR' => 73,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'OBJECT' => 74,
			'IDENTIFIER' => 87,
			'FIXED' => 48,
			'WCHAR' => 62,
			'DOUBLE' => 78,
			'error' => 275,
			'LONG' => 79,
			'STRING' => 80,
			"::" => 81,
			'OCTET' => 68,
			'FLOAT' => 70,
			'WSTRING' => 83,
			'UNSIGNED' => 59,
			'ANY' => 72
		},
		GOTOS => {
			'unsigned_int' => 46,
			'floating_pt_type' => 47,
			'signed_int' => 49,
			'wide_string_type' => 183,
			'integer_type' => 76,
			'boolean_type' => 77,
			'char_type' => 51,
			'object_type' => 52,
			'octet_type' => 53,
			'scoped_name' => 179,
			'wide_char_type' => 55,
			'signed_long_int' => 56,
			'signed_short_int' => 82,
			'string_type' => 180,
			'base_type_spec' => 181,
			'unsigned_longlong_int' => 63,
			'any_type' => 64,
			'unsigned_long_int' => 89,
			'param_type_spec' => 276,
			'unsigned_short_int' => 69,
			'fixed_pt_type' => 186,
			'signed_longlong_int' => 71
		}
	},
	{#State 190
		DEFAULT => -25
	},
	{#State 191
		DEFAULT => -34
	},
	{#State 192
		DEFAULT => -39
	},
	{#State 193
		DEFAULT => -32
	},
	{#State 194
		ACTIONS => {
			'error' => 278,
			")" => 282,
			'OUT' => 283,
			'INOUT' => 279,
			'IN' => 277
		},
		GOTOS => {
			'param_dcl' => 284,
			'param_dcls' => 281,
			'param_attribute' => 280
		}
	},
	{#State 195
		DEFAULT => -239
	},
	{#State 196
		ACTIONS => {
			'RAISES' => 288,
			'CONTEXT' => 285
		},
		DEFAULT => -235,
		GOTOS => {
			'context_expr' => 287,
			'raises_expr' => 286
		}
	},
	{#State 197
		DEFAULT => -37
	},
	{#State 198
		DEFAULT => -42
	},
	{#State 199
		DEFAULT => -36
	},
	{#State 200
		DEFAULT => -41
	},
	{#State 201
		DEFAULT => -33
	},
	{#State 202
		DEFAULT => -38
	},
	{#State 203
		DEFAULT => -24
	},
	{#State 204
		DEFAULT => -17
	},
	{#State 205
		DEFAULT => -16
	},
	{#State 206
		ACTIONS => {
			'error' => 290,
			";" => 289
		}
	},
	{#State 207
		DEFAULT => -231
	},
	{#State 208
		DEFAULT => -230
	},
	{#State 209
		DEFAULT => -170
	},
	{#State 210
		DEFAULT => -96
	},
	{#State 211
		DEFAULT => -97
	},
	{#State 212
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -89
	},
	{#State 213
		ACTIONS => {
			"," => 291
		}
	},
	{#State 214
		DEFAULT => -95
	},
	{#State 215
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'CHARACTER_LITERAL' => 210,
			'WIDE_CHARACTER_LITERAL' => 211,
			"::" => 81,
			'INTEGER_LITERAL' => 231,
			"(" => 215,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'FIXED_PT_LITERAL' => 234,
			"+" => 235,
			'error' => 293,
			"-" => 237,
			'WIDE_STRING_LITERAL' => 223,
			'FALSE' => 222,
			"~" => 238,
			'TRUE' => 225
		},
		GOTOS => {
			'mult_expr' => 232,
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'const_exp' => 292,
			'and_expr' => 230,
			'or_expr' => 218,
			'unary_expr' => 236,
			'scoped_name' => 212,
			'xor_expr' => 220,
			'shift_expr' => 221,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 216
		DEFAULT => -100
	},
	{#State 217
		DEFAULT => -107
	},
	{#State 218
		ACTIONS => {
			"|" => 294
		},
		DEFAULT => -67
	},
	{#State 219
		ACTIONS => {
			">" => 295
		}
	},
	{#State 220
		ACTIONS => {
			"^" => 296
		},
		DEFAULT => -68
	},
	{#State 221
		ACTIONS => {
			"<<" => 297,
			">>" => 298
		},
		DEFAULT => -72
	},
	{#State 222
		DEFAULT => -106
	},
	{#State 223
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 223
		},
		DEFAULT => -103,
		GOTOS => {
			'wide_string_literal' => 299
		}
	},
	{#State 224
		DEFAULT => -90
	},
	{#State 225
		DEFAULT => -105
	},
	{#State 226
		ACTIONS => {
			"+" => 300,
			"-" => 301
		},
		DEFAULT => -74
	},
	{#State 227
		DEFAULT => -94
	},
	{#State 228
		DEFAULT => -99
	},
	{#State 229
		DEFAULT => -85
	},
	{#State 230
		ACTIONS => {
			"&" => 302
		},
		DEFAULT => -70
	},
	{#State 231
		DEFAULT => -93
	},
	{#State 232
		ACTIONS => {
			"%" => 304,
			"*" => 303,
			"/" => 305
		},
		DEFAULT => -77
	},
	{#State 233
		ACTIONS => {
			'STRING_LITERAL' => 233
		},
		DEFAULT => -101,
		GOTOS => {
			'string_literal' => 306
		}
	},
	{#State 234
		DEFAULT => -98
	},
	{#State 235
		DEFAULT => -87
	},
	{#State 236
		DEFAULT => -80
	},
	{#State 237
		DEFAULT => -86
	},
	{#State 238
		DEFAULT => -88
	},
	{#State 239
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'string_literal' => 227,
			'boolean_literal' => 216,
			'scoped_name' => 212,
			'primary_expr' => 307,
			'literal' => 224,
			'wide_string_literal' => 214
		}
	},
	{#State 240
		ACTIONS => {
			">" => 308
		}
	},
	{#State 241
		ACTIONS => {
			">" => 310,
			"," => 309
		}
	},
	{#State 242
		DEFAULT => -52
	},
	{#State 243
		DEFAULT => -51
	},
	{#State 244
		ACTIONS => {
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'declarators' => 311,
			'declarator' => 153,
			'simple_declarator' => 156,
			'array_declarator' => 157,
			'complex_declarator' => 155
		}
	},
	{#State 245
		DEFAULT => -217
	},
	{#State 246
		ACTIONS => {
			"[" => 247
		},
		DEFAULT => -218,
		GOTOS => {
			'fixed_array_sizes' => 312,
			'fixed_array_size' => 246
		}
	},
	{#State 247
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'CHARACTER_LITERAL' => 210,
			'WIDE_CHARACTER_LITERAL' => 211,
			"::" => 81,
			'INTEGER_LITERAL' => 231,
			"(" => 215,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'FIXED_PT_LITERAL' => 234,
			"+" => 235,
			'error' => 314,
			"-" => 237,
			'WIDE_STRING_LITERAL' => 223,
			'FALSE' => 222,
			"~" => 238,
			'TRUE' => 225
		},
		GOTOS => {
			'string_literal' => 227,
			'primary_expr' => 229,
			'and_expr' => 230,
			'scoped_name' => 212,
			'positive_int_const' => 313,
			'wide_string_literal' => 214,
			'boolean_literal' => 216,
			'mult_expr' => 232,
			'const_exp' => 217,
			'or_expr' => 218,
			'unary_expr' => 236,
			'xor_expr' => 220,
			'shift_expr' => 221,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 248
		DEFAULT => -159
	},
	{#State 249
		ACTIONS => {
			">" => 315
		}
	},
	{#State 250
		ACTIONS => {
			">" => 316
		}
	},
	{#State 251
		ACTIONS => {
			">" => 317
		}
	},
	{#State 252
		ACTIONS => {
			">" => 318
		}
	},
	{#State 253
		DEFAULT => -167
	},
	{#State 254
		DEFAULT => -166
	},
	{#State 255
		DEFAULT => -197
	},
	{#State 256
		DEFAULT => -204
	},
	{#State 257
		ACTIONS => {
			'IDENTIFIER' => 171
		},
		DEFAULT => -203,
		GOTOS => {
			'enumerators' => 319,
			'enumerator' => 170
		}
	},
	{#State 258
		DEFAULT => -196
	},
	{#State 259
		DEFAULT => -55
	},
	{#State 260
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'CHARACTER_LITERAL' => 210,
			'WIDE_CHARACTER_LITERAL' => 211,
			"::" => 81,
			'INTEGER_LITERAL' => 231,
			"(" => 215,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'FIXED_PT_LITERAL' => 234,
			"+" => 235,
			'error' => 321,
			"-" => 237,
			'WIDE_STRING_LITERAL' => 223,
			'FALSE' => 222,
			"~" => 238,
			'TRUE' => 225
		},
		GOTOS => {
			'mult_expr' => 232,
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'const_exp' => 320,
			'and_expr' => 230,
			'or_expr' => 218,
			'unary_expr' => 236,
			'scoped_name' => 212,
			'xor_expr' => 220,
			'shift_expr' => 221,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 261
		DEFAULT => -180
	},
	{#State 262
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -183
	},
	{#State 263
		DEFAULT => -182
	},
	{#State 264
		ACTIONS => {
			")" => 322
		}
	},
	{#State 265
		ACTIONS => {
			")" => 323
		}
	},
	{#State 266
		DEFAULT => -181
	},
	{#State 267
		DEFAULT => -179
	},
	{#State 268
		ACTIONS => {
			'LONG' => 162
		},
		DEFAULT => -152
	},
	{#State 269
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -47
	},
	{#State 270
		DEFAULT => -44
	},
	{#State 271
		ACTIONS => {
			"," => 324
		},
		DEFAULT => -45
	},
	{#State 272
		DEFAULT => -43
	},
	{#State 273
		DEFAULT => -241
	},
	{#State 274
		DEFAULT => -240
	},
	{#State 275
		DEFAULT => -224
	},
	{#State 276
		ACTIONS => {
			'error' => 325,
			'IDENTIFIER' => 33
		},
		GOTOS => {
			'simple_declarators' => 327,
			'simple_declarator' => 326
		}
	},
	{#State 277
		DEFAULT => -255
	},
	{#State 278
		ACTIONS => {
			")" => 328
		}
	},
	{#State 279
		DEFAULT => -257
	},
	{#State 280
		ACTIONS => {
			'CHAR' => 73,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'OBJECT' => 74,
			'IDENTIFIER' => 87,
			'FIXED' => 48,
			'WCHAR' => 62,
			'DOUBLE' => 78,
			'LONG' => 79,
			'STRING' => 80,
			"::" => 81,
			'OCTET' => 68,
			'FLOAT' => 70,
			'WSTRING' => 83,
			'UNSIGNED' => 59,
			'ANY' => 72
		},
		GOTOS => {
			'unsigned_int' => 46,
			'floating_pt_type' => 47,
			'signed_int' => 49,
			'wide_string_type' => 183,
			'integer_type' => 76,
			'boolean_type' => 77,
			'char_type' => 51,
			'object_type' => 52,
			'octet_type' => 53,
			'scoped_name' => 179,
			'wide_char_type' => 55,
			'signed_long_int' => 56,
			'signed_short_int' => 82,
			'string_type' => 180,
			'base_type_spec' => 181,
			'unsigned_longlong_int' => 63,
			'any_type' => 64,
			'unsigned_long_int' => 89,
			'param_type_spec' => 329,
			'unsigned_short_int' => 69,
			'fixed_pt_type' => 186,
			'signed_longlong_int' => 71
		}
	},
	{#State 281
		ACTIONS => {
			")" => 330
		}
	},
	{#State 282
		DEFAULT => -248
	},
	{#State 283
		DEFAULT => -256
	},
	{#State 284
		ACTIONS => {
			";" => 331,
			"," => 332
		},
		DEFAULT => -250
	},
	{#State 285
		ACTIONS => {
			'error' => 334,
			"(" => 333
		}
	},
	{#State 286
		ACTIONS => {
			'CONTEXT' => 285
		},
		DEFAULT => -236,
		GOTOS => {
			'context_expr' => 335
		}
	},
	{#State 287
		DEFAULT => -238
	},
	{#State 288
		ACTIONS => {
			'error' => 337,
			"(" => 336
		}
	},
	{#State 289
		DEFAULT => -171
	},
	{#State 290
		DEFAULT => -172
	},
	{#State 291
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'CHARACTER_LITERAL' => 210,
			'WIDE_CHARACTER_LITERAL' => 211,
			"::" => 81,
			'INTEGER_LITERAL' => 231,
			"(" => 215,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'FIXED_PT_LITERAL' => 234,
			"+" => 235,
			'error' => 339,
			"-" => 237,
			'WIDE_STRING_LITERAL' => 223,
			'FALSE' => 222,
			"~" => 238,
			'TRUE' => 225
		},
		GOTOS => {
			'string_literal' => 227,
			'primary_expr' => 229,
			'and_expr' => 230,
			'scoped_name' => 212,
			'positive_int_const' => 338,
			'wide_string_literal' => 214,
			'boolean_literal' => 216,
			'mult_expr' => 232,
			'const_exp' => 217,
			'or_expr' => 218,
			'unary_expr' => 236,
			'xor_expr' => 220,
			'shift_expr' => 221,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 292
		ACTIONS => {
			")" => 340
		}
	},
	{#State 293
		ACTIONS => {
			")" => 341
		}
	},
	{#State 294
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			"+" => 235,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"-" => 237,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"~" => 238,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'mult_expr' => 232,
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'and_expr' => 230,
			'unary_expr' => 236,
			'scoped_name' => 212,
			'xor_expr' => 342,
			'shift_expr' => 221,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 295
		DEFAULT => -276
	},
	{#State 296
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			"+" => 235,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"-" => 237,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"~" => 238,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'mult_expr' => 232,
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'and_expr' => 343,
			'unary_expr' => 236,
			'scoped_name' => 212,
			'shift_expr' => 221,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 297
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			"+" => 235,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"-" => 237,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"~" => 238,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'mult_expr' => 232,
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'unary_expr' => 236,
			'scoped_name' => 212,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 344
		}
	},
	{#State 298
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			"+" => 235,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"-" => 237,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"~" => 238,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'mult_expr' => 232,
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'unary_expr' => 236,
			'scoped_name' => 212,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 345
		}
	},
	{#State 299
		DEFAULT => -104
	},
	{#State 300
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			"+" => 235,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"-" => 237,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"~" => 238,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'mult_expr' => 346,
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'unary_expr' => 236,
			'scoped_name' => 212,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239
		}
	},
	{#State 301
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			"+" => 235,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"-" => 237,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"~" => 238,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'mult_expr' => 347,
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'unary_expr' => 236,
			'scoped_name' => 212,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239
		}
	},
	{#State 302
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			"+" => 235,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"-" => 237,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"~" => 238,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'mult_expr' => 232,
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'unary_expr' => 236,
			'scoped_name' => 212,
			'shift_expr' => 348,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 303
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			"+" => 235,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"-" => 237,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"~" => 238,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'unary_expr' => 349,
			'scoped_name' => 212,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239
		}
	},
	{#State 304
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			"+" => 235,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"-" => 237,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"~" => 238,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'unary_expr' => 350,
			'scoped_name' => 212,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239
		}
	},
	{#State 305
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 210,
			"+" => 235,
			'FIXED_PT_LITERAL' => 234,
			'WIDE_CHARACTER_LITERAL' => 211,
			"-" => 237,
			"::" => 81,
			'FALSE' => 222,
			'WIDE_STRING_LITERAL' => 223,
			'INTEGER_LITERAL' => 231,
			"~" => 238,
			"(" => 215,
			'TRUE' => 225
		},
		GOTOS => {
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'unary_expr' => 351,
			'scoped_name' => 212,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239
		}
	},
	{#State 306
		DEFAULT => -102
	},
	{#State 307
		DEFAULT => -84
	},
	{#State 308
		DEFAULT => -209
	},
	{#State 309
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'CHARACTER_LITERAL' => 210,
			'WIDE_CHARACTER_LITERAL' => 211,
			"::" => 81,
			'INTEGER_LITERAL' => 231,
			"(" => 215,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'FIXED_PT_LITERAL' => 234,
			"+" => 235,
			'error' => 353,
			"-" => 237,
			'WIDE_STRING_LITERAL' => 223,
			'FALSE' => 222,
			"~" => 238,
			'TRUE' => 225
		},
		GOTOS => {
			'string_literal' => 227,
			'primary_expr' => 229,
			'and_expr' => 230,
			'scoped_name' => 212,
			'positive_int_const' => 352,
			'wide_string_literal' => 214,
			'boolean_literal' => 216,
			'mult_expr' => 232,
			'const_exp' => 217,
			'or_expr' => 218,
			'unary_expr' => 236,
			'xor_expr' => 220,
			'shift_expr' => 221,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 310
		DEFAULT => -208
	},
	{#State 311
		DEFAULT => -138
	},
	{#State 312
		DEFAULT => -219
	},
	{#State 313
		ACTIONS => {
			"]" => 354
		}
	},
	{#State 314
		ACTIONS => {
			"]" => 355
		}
	},
	{#State 315
		DEFAULT => -211
	},
	{#State 316
		DEFAULT => -213
	},
	{#State 317
		DEFAULT => -214
	},
	{#State 318
		DEFAULT => -216
	},
	{#State 319
		DEFAULT => -202
	},
	{#State 320
		DEFAULT => -53
	},
	{#State 321
		DEFAULT => -54
	},
	{#State 322
		DEFAULT => -176
	},
	{#State 323
		ACTIONS => {
			"{" => 357,
			'error' => 356
		}
	},
	{#State 324
		ACTIONS => {
			'IDENTIFIER' => 87,
			"::" => 81
		},
		GOTOS => {
			'scoped_name' => 269,
			'interface_names' => 358,
			'interface_name' => 271
		}
	},
	{#State 325
		DEFAULT => -223
	},
	{#State 326
		ACTIONS => {
			"," => 359
		},
		DEFAULT => -227
	},
	{#State 327
		DEFAULT => -222
	},
	{#State 328
		DEFAULT => -249
	},
	{#State 329
		ACTIONS => {
			'IDENTIFIER' => 33
		},
		GOTOS => {
			'simple_declarator' => 360
		}
	},
	{#State 330
		DEFAULT => -247
	},
	{#State 331
		DEFAULT => -253
	},
	{#State 332
		ACTIONS => {
			'OUT' => 283,
			'INOUT' => 279,
			'IN' => 277
		},
		DEFAULT => -252,
		GOTOS => {
			'param_dcl' => 284,
			'param_dcls' => 361,
			'param_attribute' => 280
		}
	},
	{#State 333
		ACTIONS => {
			'error' => 362,
			'STRING_LITERAL' => 233
		},
		GOTOS => {
			'string_literal' => 363,
			'string_literals' => 364
		}
	},
	{#State 334
		DEFAULT => -266
	},
	{#State 335
		DEFAULT => -237
	},
	{#State 336
		ACTIONS => {
			'error' => 366,
			'IDENTIFIER' => 87,
			"::" => 81
		},
		GOTOS => {
			'scoped_name' => 365,
			'exception_names' => 367,
			'exception_name' => 368
		}
	},
	{#State 337
		DEFAULT => -260
	},
	{#State 338
		ACTIONS => {
			">" => 369
		}
	},
	{#State 339
		ACTIONS => {
			">" => 370
		}
	},
	{#State 340
		DEFAULT => -91
	},
	{#State 341
		DEFAULT => -92
	},
	{#State 342
		ACTIONS => {
			"^" => 296
		},
		DEFAULT => -69
	},
	{#State 343
		ACTIONS => {
			"&" => 302
		},
		DEFAULT => -71
	},
	{#State 344
		ACTIONS => {
			"+" => 300,
			"-" => 301
		},
		DEFAULT => -76
	},
	{#State 345
		ACTIONS => {
			"+" => 300,
			"-" => 301
		},
		DEFAULT => -75
	},
	{#State 346
		ACTIONS => {
			"%" => 304,
			"*" => 303,
			"/" => 305
		},
		DEFAULT => -78
	},
	{#State 347
		ACTIONS => {
			"%" => 304,
			"*" => 303,
			"/" => 305
		},
		DEFAULT => -79
	},
	{#State 348
		ACTIONS => {
			"<<" => 297,
			">>" => 298
		},
		DEFAULT => -73
	},
	{#State 349
		DEFAULT => -81
	},
	{#State 350
		DEFAULT => -83
	},
	{#State 351
		DEFAULT => -82
	},
	{#State 352
		ACTIONS => {
			">" => 371
		}
	},
	{#State 353
		ACTIONS => {
			">" => 372
		}
	},
	{#State 354
		DEFAULT => -220
	},
	{#State 355
		DEFAULT => -221
	},
	{#State 356
		DEFAULT => -175
	},
	{#State 357
		ACTIONS => {
			'error' => 376,
			'CASE' => 373,
			'DEFAULT' => 375
		},
		GOTOS => {
			'case_labels' => 378,
			'switch_body' => 377,
			'case' => 374,
			'case_label' => 379
		}
	},
	{#State 358
		DEFAULT => -46
	},
	{#State 359
		ACTIONS => {
			'IDENTIFIER' => 33
		},
		GOTOS => {
			'simple_declarators' => 380,
			'simple_declarator' => 326
		}
	},
	{#State 360
		DEFAULT => -254
	},
	{#State 361
		DEFAULT => -251
	},
	{#State 362
		ACTIONS => {
			")" => 381
		}
	},
	{#State 363
		ACTIONS => {
			"," => 382
		},
		DEFAULT => -267
	},
	{#State 364
		ACTIONS => {
			")" => 383
		}
	},
	{#State 365
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -263
	},
	{#State 366
		ACTIONS => {
			")" => 384
		}
	},
	{#State 367
		ACTIONS => {
			")" => 385
		}
	},
	{#State 368
		ACTIONS => {
			"," => 386
		},
		DEFAULT => -261
	},
	{#State 369
		DEFAULT => -274
	},
	{#State 370
		DEFAULT => -275
	},
	{#State 371
		DEFAULT => -206
	},
	{#State 372
		DEFAULT => -207
	},
	{#State 373
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 228,
			'CHARACTER_LITERAL' => 210,
			'WIDE_CHARACTER_LITERAL' => 211,
			"::" => 81,
			'INTEGER_LITERAL' => 231,
			"(" => 215,
			'IDENTIFIER' => 87,
			'STRING_LITERAL' => 233,
			'FIXED_PT_LITERAL' => 234,
			"+" => 235,
			'error' => 388,
			"-" => 237,
			'WIDE_STRING_LITERAL' => 223,
			'FALSE' => 222,
			"~" => 238,
			'TRUE' => 225
		},
		GOTOS => {
			'mult_expr' => 232,
			'string_literal' => 227,
			'boolean_literal' => 216,
			'primary_expr' => 229,
			'const_exp' => 387,
			'and_expr' => 230,
			'or_expr' => 218,
			'unary_expr' => 236,
			'scoped_name' => 212,
			'xor_expr' => 220,
			'shift_expr' => 221,
			'wide_string_literal' => 214,
			'literal' => 224,
			'unary_operator' => 239,
			'add_expr' => 226
		}
	},
	{#State 374
		ACTIONS => {
			'CASE' => 373,
			'DEFAULT' => 375
		},
		DEFAULT => -184,
		GOTOS => {
			'case_labels' => 378,
			'switch_body' => 389,
			'case' => 374,
			'case_label' => 379
		}
	},
	{#State 375
		ACTIONS => {
			'error' => 390,
			":" => 391
		}
	},
	{#State 376
		ACTIONS => {
			"}" => 392
		}
	},
	{#State 377
		ACTIONS => {
			"}" => 393
		}
	},
	{#State 378
		ACTIONS => {
			'CHAR' => 73,
			'OBJECT' => 74,
			'FIXED' => 48,
			'SEQUENCE' => 50,
			'STRUCT' => 6,
			'DOUBLE' => 78,
			'LONG' => 79,
			'STRING' => 80,
			"::" => 81,
			'WSTRING' => 83,
			'UNSIGNED' => 59,
			'SHORT' => 61,
			'BOOLEAN' => 85,
			'IDENTIFIER' => 87,
			'UNION' => 16,
			'WCHAR' => 62,
			'FLOAT' => 70,
			'OCTET' => 68,
			'ENUM' => 28,
			'ANY' => 72
		},
		GOTOS => {
			'unsigned_int' => 46,
			'floating_pt_type' => 47,
			'signed_int' => 49,
			'char_type' => 51,
			'object_type' => 52,
			'octet_type' => 53,
			'scoped_name' => 54,
			'wide_char_type' => 55,
			'signed_long_int' => 56,
			'type_spec' => 394,
			'string_type' => 60,
			'struct_header' => 13,
			'element_spec' => 395,
			'unsigned_longlong_int' => 63,
			'any_type' => 64,
			'base_type_spec' => 65,
			'enum_type' => 66,
			'enum_header' => 20,
			'union_header' => 24,
			'unsigned_short_int' => 69,
			'signed_longlong_int' => 71,
			'wide_string_type' => 75,
			'boolean_type' => 77,
			'integer_type' => 76,
			'signed_short_int' => 82,
			'struct_type' => 84,
			'union_type' => 86,
			'sequence_type' => 88,
			'unsigned_long_int' => 89,
			'template_type_spec' => 90,
			'constr_type_spec' => 91,
			'simple_type_spec' => 92,
			'fixed_pt_type' => 93
		}
	},
	{#State 379
		ACTIONS => {
			'CASE' => 373,
			'DEFAULT' => 375
		},
		DEFAULT => -188,
		GOTOS => {
			'case_labels' => 396,
			'case_label' => 379
		}
	},
	{#State 380
		DEFAULT => -228
	},
	{#State 381
		DEFAULT => -265
	},
	{#State 382
		ACTIONS => {
			'STRING_LITERAL' => 233
		},
		GOTOS => {
			'string_literal' => 363,
			'string_literals' => 397
		}
	},
	{#State 383
		DEFAULT => -264
	},
	{#State 384
		DEFAULT => -259
	},
	{#State 385
		DEFAULT => -258
	},
	{#State 386
		ACTIONS => {
			'IDENTIFIER' => 87,
			"::" => 81
		},
		GOTOS => {
			'scoped_name' => 365,
			'exception_names' => 398,
			'exception_name' => 368
		}
	},
	{#State 387
		ACTIONS => {
			'error' => 399,
			":" => 400
		}
	},
	{#State 388
		DEFAULT => -192
	},
	{#State 389
		DEFAULT => -185
	},
	{#State 390
		DEFAULT => -194
	},
	{#State 391
		DEFAULT => -193
	},
	{#State 392
		DEFAULT => -174
	},
	{#State 393
		DEFAULT => -173
	},
	{#State 394
		ACTIONS => {
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'declarator' => 401,
			'simple_declarator' => 156,
			'array_declarator' => 157,
			'complex_declarator' => 155
		}
	},
	{#State 395
		ACTIONS => {
			'error' => 403,
			";" => 402
		}
	},
	{#State 396
		DEFAULT => -189
	},
	{#State 397
		DEFAULT => -268
	},
	{#State 398
		DEFAULT => -262
	},
	{#State 399
		DEFAULT => -191
	},
	{#State 400
		DEFAULT => -190
	},
	{#State 401
		DEFAULT => -195
	},
	{#State 402
		DEFAULT => -186
	},
	{#State 403
		DEFAULT => -187
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
#line 59 "parser22.yp"
{ $_[0]->YYData->{list_root} = $_[1]; }
	],
	[#Rule 2
		 'specification', 0,
sub
#line 61 "parser22.yp"
{
			$_[0]->Error("Empty specification\n");
		}
	],
	[#Rule 3
		 'specification', 1, undef
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 68 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 69 "parser22.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 6
		 'definition', 2, undef
	],
	[#Rule 7
		 'definition', 2, undef
	],
	[#Rule 8
		 'definition', 2, undef
	],
	[#Rule 9
		 'definition', 2, undef
	],
	[#Rule 10
		 'definition', 2, undef
	],
	[#Rule 11
		 'definition', 2,
sub
#line 80 "parser22.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 12
		 'definition', 2,
sub
#line 86 "parser22.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 92 "parser22.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 98 "parser22.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 104 "parser22.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'module', 4,
sub
#line 114 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->configure('list_decl' => $_[3])
					if (defined $_[1]);
		}
	],
	[#Rule 17
		 'module', 4,
sub
#line 120 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 18
		 'module', 2,
sub
#line 126 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 135 "parser22.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 141 "parser22.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 21
		 'interface', 1, undef
	],
	[#Rule 22
		 'interface', 1, undef
	],
	[#Rule 23
		 'interface_dcl', 3,
sub
#line 156 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	[]);
		}
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 162 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	$_[3]);
		}
	],
	[#Rule 25
		 'interface_dcl', 4,
sub
#line 168 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 26
		 'forward_dcl', 2,
sub
#line 179 "parser22.yp"
{
			new ForwardInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 27
		 'forward_dcl', 2,
sub
#line 185 "parser22.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'interface_header', 2,
sub
#line 194 "parser22.yp"
{
			new Interface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 29
		 'interface_header', 3,
sub
#line 200 "parser22.yp"
{
			new Interface($_[0],
					'idf'					=>	$_[2],
					'list_inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 30
		 'interface_body', 1, undef
	],
	[#Rule 31
		 'exports', 1,
sub
#line 214 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 32
		 'exports', 2,
sub
#line 215 "parser22.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 33
		 'export', 2, undef
	],
	[#Rule 34
		 'export', 2, undef
	],
	[#Rule 35
		 'export', 2, undef
	],
	[#Rule 36
		 'export', 2, undef
	],
	[#Rule 37
		 'export', 2, undef
	],
	[#Rule 38
		 'export', 2,
sub
#line 226 "parser22.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 39
		 'export', 2,
sub
#line 232 "parser22.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 40
		 'export', 2,
sub
#line 238 "parser22.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 41
		 'export', 2,
sub
#line 244 "parser22.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 42
		 'export', 2,
sub
#line 250 "parser22.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 43
		 'interface_inheritance_spec', 2,
sub
#line 259 "parser22.yp"
{ $_[2]; }
	],
	[#Rule 44
		 'interface_inheritance_spec', 2,
sub
#line 261 "parser22.yp"
{
			$_[0]->Error("Interface name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 45
		 'interface_names', 1,
sub
#line 268 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 46
		 'interface_names', 3,
sub
#line 269 "parser22.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 47
		 'interface_name', 1,
sub
#line 274 "parser22.yp"
{
				Interface->Lookup($_[0],$_[1])
		}
	],
	[#Rule 48
		 'scoped_name', 1, undef
	],
	[#Rule 49
		 'scoped_name', 2,
sub
#line 283 "parser22.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 50
		 'scoped_name', 2,
sub
#line 287 "parser22.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 51
		 'scoped_name', 3,
sub
#line 293 "parser22.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 52
		 'scoped_name', 3,
sub
#line 297 "parser22.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 53
		 'const_dcl', 5,
sub
#line 307 "parser22.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 54
		 'const_dcl', 5,
sub
#line 315 "parser22.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 55
		 'const_dcl', 4,
sub
#line 320 "parser22.yp"
{
			$_[0]->Error("'=' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 56
		 'const_dcl', 3,
sub
#line 325 "parser22.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 57
		 'const_dcl', 2,
sub
#line 330 "parser22.yp"
{
			$_[0]->Error("const_type excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 58
		 'const_type', 1, undef
	],
	[#Rule 59
		 'const_type', 1, undef
	],
	[#Rule 60
		 'const_type', 1, undef
	],
	[#Rule 61
		 'const_type', 1, undef
	],
	[#Rule 62
		 'const_type', 1, undef
	],
	[#Rule 63
		 'const_type', 1, undef
	],
	[#Rule 64
		 'const_type', 1, undef
	],
	[#Rule 65
		 'const_type', 1, undef
	],
	[#Rule 66
		 'const_type', 1,
sub
#line 347 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 67
		 'const_exp', 1, undef
	],
	[#Rule 68
		 'or_expr', 1, undef
	],
	[#Rule 69
		 'or_expr', 3,
sub
#line 361 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 70
		 'xor_expr', 1, undef
	],
	[#Rule 71
		 'xor_expr', 3,
sub
#line 370 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 72
		 'and_expr', 1, undef
	],
	[#Rule 73
		 'and_expr', 3,
sub
#line 379 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 74
		 'shift_expr', 1, undef
	],
	[#Rule 75
		 'shift_expr', 3,
sub
#line 388 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 76
		 'shift_expr', 3,
sub
#line 392 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 77
		 'add_expr', 1, undef
	],
	[#Rule 78
		 'add_expr', 3,
sub
#line 401 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 79
		 'add_expr', 3,
sub
#line 405 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 80
		 'mult_expr', 1, undef
	],
	[#Rule 81
		 'mult_expr', 3,
sub
#line 414 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 82
		 'mult_expr', 3,
sub
#line 418 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 83
		 'mult_expr', 3,
sub
#line 422 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 84
		 'unary_expr', 2,
sub
#line 430 "parser22.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 85
		 'unary_expr', 1, undef
	],
	[#Rule 86
		 'unary_operator', 1, undef
	],
	[#Rule 87
		 'unary_operator', 1, undef
	],
	[#Rule 88
		 'unary_operator', 1, undef
	],
	[#Rule 89
		 'primary_expr', 1,
sub
#line 446 "parser22.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 90
		 'primary_expr', 1,
sub
#line 452 "parser22.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 91
		 'primary_expr', 3,
sub
#line 456 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 92
		 'primary_expr', 3,
sub
#line 460 "parser22.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 93
		 'literal', 1,
sub
#line 469 "parser22.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 94
		 'literal', 1,
sub
#line 476 "parser22.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 95
		 'literal', 1,
sub
#line 482 "parser22.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 96
		 'literal', 1,
sub
#line 488 "parser22.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 97
		 'literal', 1,
sub
#line 494 "parser22.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 98
		 'literal', 1,
sub
#line 500 "parser22.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 99
		 'literal', 1,
sub
#line 507 "parser22.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 100
		 'literal', 1, undef
	],
	[#Rule 101
		 'string_literal', 1, undef
	],
	[#Rule 102
		 'string_literal', 2,
sub
#line 518 "parser22.yp"
{ $_[1] . $_[2]; }
	],
	[#Rule 103
		 'wide_string_literal', 1, undef
	],
	[#Rule 104
		 'wide_string_literal', 2,
sub
#line 524 "parser22.yp"
{ $_[1] . $_[2]; }
	],
	[#Rule 105
		 'boolean_literal', 1,
sub
#line 530 "parser22.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 106
		 'boolean_literal', 1,
sub
#line 536 "parser22.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 107
		 'positive_int_const', 1,
sub
#line 546 "parser22.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 108
		 'type_dcl', 2,
sub
#line 557 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 109
		 'type_dcl', 1, undef
	],
	[#Rule 110
		 'type_dcl', 1, undef
	],
	[#Rule 111
		 'type_dcl', 1, undef
	],
	[#Rule 112
		 'type_dcl', 2,
sub
#line 564 "parser22.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 113
		 'type_dcl', 2,
sub
#line 571 "parser22.yp"
{
			$_[0]->Error("type_declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 114
		 'type_dcl', 2,
sub
#line 576 "parser22.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 115
		 'type_declarator', 2,
sub
#line 585 "parser22.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 116
		 'type_declarator', 2,
sub
#line 592 "parser22.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 117
		 'type_spec', 1, undef
	],
	[#Rule 118
		 'type_spec', 1, undef
	],
	[#Rule 119
		 'simple_type_spec', 1, undef
	],
	[#Rule 120
		 'simple_type_spec', 1, undef
	],
	[#Rule 121
		 'simple_type_spec', 1,
sub
#line 609 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 122
		 'base_type_spec', 1, undef
	],
	[#Rule 123
		 'base_type_spec', 1, undef
	],
	[#Rule 124
		 'base_type_spec', 1, undef
	],
	[#Rule 125
		 'base_type_spec', 1, undef
	],
	[#Rule 126
		 'base_type_spec', 1, undef
	],
	[#Rule 127
		 'base_type_spec', 1, undef
	],
	[#Rule 128
		 'base_type_spec', 1, undef
	],
	[#Rule 129
		 'base_type_spec', 1, undef
	],
	[#Rule 130
		 'template_type_spec', 1, undef
	],
	[#Rule 131
		 'template_type_spec', 1, undef
	],
	[#Rule 132
		 'template_type_spec', 1, undef
	],
	[#Rule 133
		 'template_type_spec', 1, undef
	],
	[#Rule 134
		 'constr_type_spec', 1, undef
	],
	[#Rule 135
		 'constr_type_spec', 1, undef
	],
	[#Rule 136
		 'constr_type_spec', 1, undef
	],
	[#Rule 137
		 'declarators', 1,
sub
#line 643 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 138
		 'declarators', 3,
sub
#line 644 "parser22.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 139
		 'declarator', 1,
sub
#line 649 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 140
		 'declarator', 1, undef
	],
	[#Rule 141
		 'simple_declarator', 1, undef
	],
	[#Rule 142
		 'complex_declarator', 1, undef
	],
	[#Rule 143
		 'floating_pt_type', 1,
sub
#line 666 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 144
		 'floating_pt_type', 1,
sub
#line 672 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 145
		 'floating_pt_type', 2,
sub
#line 678 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 146
		 'integer_type', 1, undef
	],
	[#Rule 147
		 'integer_type', 1, undef
	],
	[#Rule 148
		 'signed_int', 1, undef
	],
	[#Rule 149
		 'signed_int', 1, undef
	],
	[#Rule 150
		 'signed_int', 1, undef
	],
	[#Rule 151
		 'signed_short_int', 1,
sub
#line 701 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 152
		 'signed_long_int', 1,
sub
#line 711 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 153
		 'signed_longlong_int', 2,
sub
#line 721 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 154
		 'unsigned_int', 1, undef
	],
	[#Rule 155
		 'unsigned_int', 1, undef
	],
	[#Rule 156
		 'unsigned_int', 1, undef
	],
	[#Rule 157
		 'unsigned_short_int', 2,
sub
#line 738 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 158
		 'unsigned_long_int', 2,
sub
#line 748 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 159
		 'unsigned_longlong_int', 3,
sub
#line 758 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 160
		 'char_type', 1,
sub
#line 768 "parser22.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'wide_char_type', 1,
sub
#line 778 "parser22.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'boolean_type', 1,
sub
#line 788 "parser22.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'octet_type', 1,
sub
#line 798 "parser22.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 164
		 'any_type', 1,
sub
#line 808 "parser22.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 165
		 'object_type', 1,
sub
#line 818 "parser22.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 166
		 'struct_type', 4,
sub
#line 828 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 167
		 'struct_type', 4,
sub
#line 835 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 168
		 'struct_header', 2,
sub
#line 844 "parser22.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 169
		 'member_list', 1,
sub
#line 853 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 170
		 'member_list', 2,
sub
#line 854 "parser22.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 171
		 'member', 3,
sub
#line 860 "parser22.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 172
		 'member', 3,
sub
#line 867 "parser22.yp"
{
			$_[0]->Error("';' excepted.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 173
		 'union_type', 8,
sub
#line 880 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			);
		}
	],
	[#Rule 174
		 'union_type', 8,
sub
#line 888 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 175
		 'union_type', 6,
sub
#line 894 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 176
		 'union_type', 5,
sub
#line 900 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 177
		 'union_type', 3,
sub
#line 906 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 178
		 'union_header', 2,
sub
#line 915 "parser22.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 179
		 'switch_type_spec', 1, undef
	],
	[#Rule 180
		 'switch_type_spec', 1, undef
	],
	[#Rule 181
		 'switch_type_spec', 1, undef
	],
	[#Rule 182
		 'switch_type_spec', 1, undef
	],
	[#Rule 183
		 'switch_type_spec', 1,
sub
#line 929 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 184
		 'switch_body', 1,
sub
#line 936 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 185
		 'switch_body', 2,
sub
#line 937 "parser22.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 186
		 'case', 3,
sub
#line 943 "parser22.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 187
		 'case', 3,
sub
#line 950 "parser22.yp"
{
			$_[0]->Error("';' excepted.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 188
		 'case_labels', 1,
sub
#line 961 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 189
		 'case_labels', 2,
sub
#line 962 "parser22.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 190
		 'case_label', 3,
sub
#line 968 "parser22.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 191
		 'case_label', 3,
sub
#line 972 "parser22.yp"
{
			$_[0]->Error("':' excepted.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 192
		 'case_label', 2,
sub
#line 978 "parser22.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 193
		 'case_label', 2,
sub
#line 983 "parser22.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 194
		 'case_label', 2,
sub
#line 987 "parser22.yp"
{
			$_[0]->Error("':' excepted.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 195
		 'element_spec', 2,
sub
#line 997 "parser22.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 196
		 'enum_type', 4,
sub
#line 1008 "parser22.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 197
		 'enum_type', 4,
sub
#line 1015 "parser22.yp"
{
			$_[0]->Error("enumerator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 198
		 'enum_type', 2,
sub
#line 1020 "parser22.yp"
{
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 199
		 'enum_header', 2,
sub
#line 1028 "parser22.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 200
		 'enum_header', 2,
sub
#line 1034 "parser22.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 201
		 'enumerators', 1,
sub
#line 1041 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 202
		 'enumerators', 3,
sub
#line 1042 "parser22.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 203
		 'enumerators', 2,
sub
#line 1044 "parser22.yp"
{
			$_[0]->Warning("',' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 204
		 'enumerators', 2,
sub
#line 1049 "parser22.yp"
{
			$_[0]->Error("';' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 205
		 'enumerator', 1,
sub
#line 1058 "parser22.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 206
		 'sequence_type', 6,
sub
#line 1068 "parser22.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 207
		 'sequence_type', 6,
sub
#line 1076 "parser22.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 208
		 'sequence_type', 4,
sub
#line 1081 "parser22.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 209
		 'sequence_type', 4,
sub
#line 1088 "parser22.yp"
{
			$_[0]->Error("simple_type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 210
		 'sequence_type', 2,
sub
#line 1093 "parser22.yp"
{
			$_[0]->Error("'<' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 211
		 'string_type', 4,
sub
#line 1102 "parser22.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 212
		 'string_type', 1,
sub
#line 1109 "parser22.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 213
		 'string_type', 4,
sub
#line 1115 "parser22.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 214
		 'wide_string_type', 4,
sub
#line 1124 "parser22.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 215
		 'wide_string_type', 1,
sub
#line 1131 "parser22.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 216
		 'wide_string_type', 4,
sub
#line 1137 "parser22.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 217
		 'array_declarator', 2,
sub
#line 1145 "parser22.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 218
		 'fixed_array_sizes', 1,
sub
#line 1149 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 219
		 'fixed_array_sizes', 2,
sub
#line 1151 "parser22.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 220
		 'fixed_array_size', 3,
sub
#line 1156 "parser22.yp"
{ $_[2]; }
	],
	[#Rule 221
		 'fixed_array_size', 3,
sub
#line 1158 "parser22.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 222
		 'attr_dcl', 4,
sub
#line 1167 "parser22.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 223
		 'attr_dcl', 4,
sub
#line 1175 "parser22.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 224
		 'attr_dcl', 3,
sub
#line 1180 "parser22.yp"
{
			$_[0]->Error("type excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 225
		 'attr_mod', 1, undef
	],
	[#Rule 226
		 'attr_mod', 0, undef
	],
	[#Rule 227
		 'simple_declarators', 1,
sub
#line 1192 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 228
		 'simple_declarators', 3,
sub
#line 1194 "parser22.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 229
		 'except_dcl', 3,
sub
#line 1200 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 230
		 'except_dcl', 4,
sub
#line 1205 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 231
		 'except_dcl', 4,
sub
#line 1213 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members excepted.\n");
			$_[0]->YYErrok();
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 232
		 'except_dcl', 2,
sub
#line 1223 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 233
		 'exception_header', 2,
sub
#line 1232 "parser22.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 234
		 'exception_header', 2,
sub
#line 1238 "parser22.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 235
		 'op_dcl', 2,
sub
#line 1247 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 236
		 'op_dcl', 3,
sub
#line 1256 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 237
		 'op_dcl', 4,
sub
#line 1266 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3],
					'list_context'	=>	$_[4]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 238
		 'op_dcl', 3,
sub
#line 1277 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 239
		 'op_dcl', 2,
sub
#line 1287 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 240
		 'op_header', 3,
sub
#line 1297 "parser22.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 241
		 'op_header', 3,
sub
#line 1305 "parser22.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 242
		 'op_mod', 1, undef
	],
	[#Rule 243
		 'op_mod', 0, undef
	],
	[#Rule 244
		 'op_attribute', 1, undef
	],
	[#Rule 245
		 'op_type_spec', 1, undef
	],
	[#Rule 246
		 'op_type_spec', 1,
sub
#line 1325 "parser22.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 247
		 'parameter_dcls', 3,
sub
#line 1335 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 248
		 'parameter_dcls', 2,
sub
#line 1339 "parser22.yp"
{
			undef;
		}
	],
	[#Rule 249
		 'parameter_dcls', 3,
sub
#line 1343 "parser22.yp"
{
			$_[0]->Error("parameters declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 250
		 'param_dcls', 1,
sub
#line 1350 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 251
		 'param_dcls', 3,
sub
#line 1351 "parser22.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 252
		 'param_dcls', 2,
sub
#line 1353 "parser22.yp"
{
			$_[0]->Warning("',' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 253
		 'param_dcls', 2,
sub
#line 1358 "parser22.yp"
{
			$_[0]->Error("';' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 254
		 'param_dcl', 3,
sub
#line 1367 "parser22.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
        }
	],
	[#Rule 255
		 'param_attribute', 1, undef
	],
	[#Rule 256
		 'param_attribute', 1, undef
	],
	[#Rule 257
		 'param_attribute', 1, undef
	],
	[#Rule 258
		 'raises_expr', 4,
sub
#line 1386 "parser22.yp"
{
			$_[3];
		}
	],
	[#Rule 259
		 'raises_expr', 4,
sub
#line 1390 "parser22.yp"
{
			$_[0]->Error("name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 260
		 'raises_expr', 2,
sub
#line 1395 "parser22.yp"
{
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 261
		 'exception_names', 1,
sub
#line 1402 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 262
		 'exception_names', 3,
sub
#line 1403 "parser22.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 263
		 'exception_name', 1,
sub
#line 1408 "parser22.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 264
		 'context_expr', 4,
sub
#line 1416 "parser22.yp"
{
			$_[3];
		}
	],
	[#Rule 265
		 'context_expr', 4,
sub
#line 1420 "parser22.yp"
{
			$_[0]->Error("string excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'context_expr', 2,
sub
#line 1425 "parser22.yp"
{
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 267
		 'string_literals', 1,
sub
#line 1432 "parser22.yp"
{ [$_[1]]; }
	],
	[#Rule 268
		 'string_literals', 3,
sub
#line 1433 "parser22.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 269
		 'param_type_spec', 1, undef
	],
	[#Rule 270
		 'param_type_spec', 1, undef
	],
	[#Rule 271
		 'param_type_spec', 1, undef
	],
	[#Rule 272
		 'param_type_spec', 1, undef
	],
	[#Rule 273
		 'param_type_spec', 1,
sub
#line 1443 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 274
		 'fixed_pt_type', 6,
sub
#line 1451 "parser22.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 275
		 'fixed_pt_type', 6,
sub
#line 1459 "parser22.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 276
		 'fixed_pt_type', 4,
sub
#line 1464 "parser22.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 277
		 'fixed_pt_type', 2,
sub
#line 1469 "parser22.yp"
{
			$_[0]->Error("'<' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 278
		 'fixed_pt_const_type', 1,
sub
#line 1478 "parser22.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 1485 "parser22.yp"


use strict;
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
