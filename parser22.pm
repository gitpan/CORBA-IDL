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
			'' => -2,
			'TYPEDEF' => 12,
			'MODULE' => 15,
			'IDENTIFIER' => 14,
			'NATIVE' => 2,
			'UNION' => 17,
			'STRUCT' => 6,
			'error' => 20,
			'CONST' => 23,
			'EXCEPTION' => 24,
			'ENUM' => 29,
			'INTERFACE' => 30
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
			'interface_dcl' => 16,
			'enum_type' => 18,
			'forward_dcl' => 19,
			'module' => 22,
			'enum_header' => 21,
			'union_header' => 25,
			'type_dcl' => 26,
			'definitions' => 27,
			'definition' => 28
		}
	},
	{#State 1
		ACTIONS => {
			'error' => 32,
			";" => 31
		}
	},
	{#State 2
		ACTIONS => {
			'error' => 35,
			'IDENTIFIER' => 34
		},
		GOTOS => {
			'simple_declarator' => 33
		}
	},
	{#State 3
		ACTIONS => {
			"{" => 36
		}
	},
	{#State 4
		ACTIONS => {
			'error' => 38,
			";" => 37
		}
	},
	{#State 5
		ACTIONS => {
			'' => 39
		}
	},
	{#State 6
		ACTIONS => {
			'IDENTIFIER' => 40
		}
	},
	{#State 7
		ACTIONS => {
			"{" => 42,
			'error' => 41
		}
	},
	{#State 8
		ACTIONS => {
			'error' => 44,
			";" => 43
		}
	},
	{#State 9
		DEFAULT => -111
	},
	{#State 10
		ACTIONS => {
			"{" => 46,
			'error' => 45
		}
	},
	{#State 11
		DEFAULT => -112
	},
	{#State 12
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 79,
			'LONG' => 80,
			'STRING' => 81,
			"::" => 82,
			'WSTRING' => 84,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'IDENTIFIER' => 88,
			'UNION' => 17,
			'WCHAR' => 63,
			'error' => 68,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'type_spec' => 58,
			'signed_long_int' => 57,
			'type_declarator' => 59,
			'string_type' => 61,
			'struct_header' => 13,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'enum_type' => 67,
			'enum_header' => 21,
			'union_header' => 25,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72,
			'wide_string_type' => 76,
			'integer_type' => 77,
			'boolean_type' => 78,
			'signed_short_int' => 83,
			'struct_type' => 85,
			'union_type' => 87,
			'sequence_type' => 89,
			'unsigned_long_int' => 90,
			'template_type_spec' => 91,
			'constr_type_spec' => 92,
			'simple_type_spec' => 93,
			'fixed_pt_type' => 94
		}
	},
	{#State 13
		ACTIONS => {
			"{" => 95
		}
	},
	{#State 14
		ACTIONS => {
			'error' => 96
		}
	},
	{#State 15
		ACTIONS => {
			'error' => 97,
			'IDENTIFIER' => 98
		}
	},
	{#State 16
		DEFAULT => -22
	},
	{#State 17
		ACTIONS => {
			'IDENTIFIER' => 99
		}
	},
	{#State 18
		DEFAULT => -113
	},
	{#State 19
		DEFAULT => -23
	},
	{#State 20
		DEFAULT => -3
	},
	{#State 21
		ACTIONS => {
			"{" => 101,
			'error' => 100
		}
	},
	{#State 22
		ACTIONS => {
			'error' => 103,
			";" => 102
		}
	},
	{#State 23
		ACTIONS => {
			'CHAR' => 74,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'IDENTIFIER' => 88,
			'FIXED' => 105,
			'WCHAR' => 63,
			'DOUBLE' => 79,
			'error' => 110,
			'LONG' => 80,
			'STRING' => 81,
			"::" => 82,
			'FLOAT' => 71,
			'WSTRING' => 84,
			'UNSIGNED' => 60
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 104,
			'signed_int' => 50,
			'wide_string_type' => 111,
			'integer_type' => 113,
			'boolean_type' => 112,
			'char_type' => 106,
			'scoped_name' => 107,
			'fixed_pt_const_type' => 114,
			'wide_char_type' => 108,
			'signed_long_int' => 57,
			'signed_short_int' => 83,
			'const_type' => 115,
			'string_type' => 109,
			'unsigned_longlong_int' => 64,
			'unsigned_long_int' => 90,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72
		}
	},
	{#State 24
		ACTIONS => {
			'error' => 116,
			'IDENTIFIER' => 117
		}
	},
	{#State 25
		ACTIONS => {
			'SWITCH' => 118
		}
	},
	{#State 26
		ACTIONS => {
			'error' => 120,
			";" => 119
		}
	},
	{#State 27
		DEFAULT => -1
	},
	{#State 28
		ACTIONS => {
			'TYPEDEF' => 12,
			'IDENTIFIER' => 14,
			'NATIVE' => 2,
			'MODULE' => 15,
			'UNION' => 17,
			'STRUCT' => 6,
			'CONST' => 23,
			'EXCEPTION' => 24,
			'ENUM' => 29,
			'INTERFACE' => 30
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
			'interface_dcl' => 16,
			'enum_type' => 18,
			'forward_dcl' => 19,
			'enum_header' => 21,
			'module' => 22,
			'union_header' => 25,
			'definitions' => 121,
			'type_dcl' => 26,
			'definition' => 28
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 122,
			'IDENTIFIER' => 123
		}
	},
	{#State 30
		ACTIONS => {
			'error' => 124,
			'IDENTIFIER' => 125
		}
	},
	{#State 31
		DEFAULT => -7
	},
	{#State 32
		DEFAULT => -12
	},
	{#State 33
		DEFAULT => -114
	},
	{#State 34
		DEFAULT => -143
	},
	{#State 35
		DEFAULT => -116
	},
	{#State 36
		ACTIONS => {
			'CHAR' => -245,
			'OBJECT' => -245,
			'ONEWAY' => 126,
			'FIXED' => -245,
			'NATIVE' => 2,
			'VOID' => -245,
			'STRUCT' => 6,
			'DOUBLE' => -245,
			'LONG' => -245,
			'STRING' => -245,
			"::" => -245,
			'WSTRING' => -245,
			'UNSIGNED' => -245,
			'SHORT' => -245,
			'TYPEDEF' => 12,
			'BOOLEAN' => -245,
			'IDENTIFIER' => -245,
			'UNION' => 17,
			'READONLY' => 137,
			'WCHAR' => -245,
			'ATTRIBUTE' => -228,
			'error' => 131,
			'CONST' => 23,
			"}" => 132,
			'EXCEPTION' => 24,
			'OCTET' => -245,
			'FLOAT' => -245,
			'ENUM' => 29,
			'ANY' => -245
		},
		GOTOS => {
			'const_dcl' => 133,
			'op_mod' => 127,
			'except_dcl' => 128,
			'op_attribute' => 129,
			'attr_mod' => 130,
			'exports' => 134,
			'export' => 135,
			'struct_type' => 9,
			'op_header' => 136,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'enum_type' => 18,
			'op_dcl' => 138,
			'enum_header' => 21,
			'attr_dcl' => 139,
			'type_dcl' => 140,
			'union_header' => 25,
			'interface_body' => 141
		}
	},
	{#State 37
		DEFAULT => -8
	},
	{#State 38
		DEFAULT => -13
	},
	{#State 39
		DEFAULT => 0
	},
	{#State 40
		DEFAULT => -170
	},
	{#State 41
		DEFAULT => -19
	},
	{#State 42
		ACTIONS => {
			'TYPEDEF' => 12,
			'IDENTIFIER' => 14,
			'NATIVE' => 2,
			'MODULE' => 15,
			'UNION' => 17,
			'STRUCT' => 6,
			'error' => 142,
			'CONST' => 23,
			'EXCEPTION' => 24,
			'ENUM' => 29,
			'INTERFACE' => 30
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
			'interface_dcl' => 16,
			'enum_type' => 18,
			'forward_dcl' => 19,
			'enum_header' => 21,
			'module' => 22,
			'union_header' => 25,
			'definitions' => 143,
			'type_dcl' => 26,
			'definition' => 28
		}
	},
	{#State 43
		DEFAULT => -9
	},
	{#State 44
		DEFAULT => -14
	},
	{#State 45
		DEFAULT => -234
	},
	{#State 46
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 79,
			'LONG' => 80,
			'STRING' => 81,
			"::" => 82,
			'WSTRING' => 84,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'IDENTIFIER' => 88,
			'UNION' => 17,
			'WCHAR' => 63,
			'error' => 145,
			"}" => 147,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'type_spec' => 144,
			'string_type' => 61,
			'struct_header' => 13,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'enum_type' => 67,
			'enum_header' => 21,
			'member_list' => 146,
			'union_header' => 25,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72,
			'wide_string_type' => 76,
			'boolean_type' => 78,
			'integer_type' => 77,
			'signed_short_int' => 83,
			'member' => 148,
			'struct_type' => 85,
			'union_type' => 87,
			'sequence_type' => 89,
			'unsigned_long_int' => 90,
			'template_type_spec' => 91,
			'constr_type_spec' => 92,
			'simple_type_spec' => 93,
			'fixed_pt_type' => 94
		}
	},
	{#State 47
		DEFAULT => -149
	},
	{#State 48
		DEFAULT => -124
	},
	{#State 49
		ACTIONS => {
			"<" => 150,
			'error' => 149
		}
	},
	{#State 50
		DEFAULT => -148
	},
	{#State 51
		ACTIONS => {
			"<" => 152,
			'error' => 151
		}
	},
	{#State 52
		DEFAULT => -126
	},
	{#State 53
		DEFAULT => -131
	},
	{#State 54
		DEFAULT => -129
	},
	{#State 55
		ACTIONS => {
			"::" => 153
		},
		DEFAULT => -123
	},
	{#State 56
		DEFAULT => -127
	},
	{#State 57
		DEFAULT => -151
	},
	{#State 58
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 160
		},
		GOTOS => {
			'declarators' => 154,
			'declarator' => 155,
			'simple_declarator' => 158,
			'array_declarator' => 159,
			'complex_declarator' => 157
		}
	},
	{#State 59
		DEFAULT => -110
	},
	{#State 60
		ACTIONS => {
			'SHORT' => 161,
			'LONG' => 162
		}
	},
	{#State 61
		DEFAULT => -133
	},
	{#State 62
		DEFAULT => -153
	},
	{#State 63
		DEFAULT => -163
	},
	{#State 64
		DEFAULT => -158
	},
	{#State 65
		DEFAULT => -130
	},
	{#State 66
		DEFAULT => -121
	},
	{#State 67
		DEFAULT => -138
	},
	{#State 68
		DEFAULT => -115
	},
	{#State 69
		DEFAULT => -165
	},
	{#State 70
		DEFAULT => -156
	},
	{#State 71
		DEFAULT => -145
	},
	{#State 72
		DEFAULT => -152
	},
	{#State 73
		DEFAULT => -166
	},
	{#State 74
		DEFAULT => -162
	},
	{#State 75
		DEFAULT => -167
	},
	{#State 76
		DEFAULT => -134
	},
	{#State 77
		DEFAULT => -125
	},
	{#State 78
		DEFAULT => -128
	},
	{#State 79
		DEFAULT => -146
	},
	{#State 80
		ACTIONS => {
			'LONG' => 164,
			'DOUBLE' => 163
		},
		DEFAULT => -154
	},
	{#State 81
		ACTIONS => {
			"<" => 165
		},
		DEFAULT => -214
	},
	{#State 82
		ACTIONS => {
			'error' => 166,
			'IDENTIFIER' => 167
		}
	},
	{#State 83
		DEFAULT => -150
	},
	{#State 84
		ACTIONS => {
			"<" => 168
		},
		DEFAULT => -217
	},
	{#State 85
		DEFAULT => -136
	},
	{#State 86
		DEFAULT => -164
	},
	{#State 87
		DEFAULT => -137
	},
	{#State 88
		DEFAULT => -50
	},
	{#State 89
		DEFAULT => -132
	},
	{#State 90
		DEFAULT => -157
	},
	{#State 91
		DEFAULT => -122
	},
	{#State 92
		DEFAULT => -120
	},
	{#State 93
		DEFAULT => -119
	},
	{#State 94
		DEFAULT => -135
	},
	{#State 95
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 79,
			'LONG' => 80,
			'STRING' => 81,
			"::" => 82,
			'WSTRING' => 84,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'IDENTIFIER' => 88,
			'UNION' => 17,
			'WCHAR' => 63,
			'error' => 169,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'type_spec' => 144,
			'string_type' => 61,
			'struct_header' => 13,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'enum_type' => 67,
			'enum_header' => 21,
			'member_list' => 170,
			'union_header' => 25,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72,
			'wide_string_type' => 76,
			'boolean_type' => 78,
			'integer_type' => 77,
			'signed_short_int' => 83,
			'member' => 148,
			'struct_type' => 85,
			'union_type' => 87,
			'sequence_type' => 89,
			'unsigned_long_int' => 90,
			'template_type_spec' => 91,
			'constr_type_spec' => 92,
			'simple_type_spec' => 93,
			'fixed_pt_type' => 94
		}
	},
	{#State 96
		ACTIONS => {
			";" => 171
		}
	},
	{#State 97
		DEFAULT => -21
	},
	{#State 98
		DEFAULT => -20
	},
	{#State 99
		DEFAULT => -180
	},
	{#State 100
		DEFAULT => -200
	},
	{#State 101
		ACTIONS => {
			'error' => 172,
			'IDENTIFIER' => 174
		},
		GOTOS => {
			'enumerators' => 175,
			'enumerator' => 173
		}
	},
	{#State 102
		DEFAULT => -10
	},
	{#State 103
		DEFAULT => -15
	},
	{#State 104
		DEFAULT => -64
	},
	{#State 105
		DEFAULT => -280
	},
	{#State 106
		DEFAULT => -61
	},
	{#State 107
		ACTIONS => {
			"::" => 153
		},
		DEFAULT => -68
	},
	{#State 108
		DEFAULT => -62
	},
	{#State 109
		DEFAULT => -65
	},
	{#State 110
		DEFAULT => -59
	},
	{#State 111
		DEFAULT => -66
	},
	{#State 112
		DEFAULT => -63
	},
	{#State 113
		DEFAULT => -60
	},
	{#State 114
		DEFAULT => -67
	},
	{#State 115
		ACTIONS => {
			'error' => 176,
			'IDENTIFIER' => 177
		}
	},
	{#State 116
		DEFAULT => -236
	},
	{#State 117
		DEFAULT => -235
	},
	{#State 118
		ACTIONS => {
			'error' => 179,
			"(" => 178
		}
	},
	{#State 119
		DEFAULT => -6
	},
	{#State 120
		DEFAULT => -11
	},
	{#State 121
		DEFAULT => -5
	},
	{#State 122
		DEFAULT => -202
	},
	{#State 123
		DEFAULT => -201
	},
	{#State 124
		ACTIONS => {
			"{" => -31
		},
		DEFAULT => -28
	},
	{#State 125
		ACTIONS => {
			"{" => -29,
			":" => 180
		},
		DEFAULT => -27,
		GOTOS => {
			'interface_inheritance_spec' => 181
		}
	},
	{#State 126
		DEFAULT => -246
	},
	{#State 127
		ACTIONS => {
			'CHAR' => 74,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'OBJECT' => 75,
			'IDENTIFIER' => 88,
			'FIXED' => 49,
			'VOID' => 187,
			'WCHAR' => 63,
			'DOUBLE' => 79,
			'LONG' => 80,
			'STRING' => 81,
			"::" => 82,
			'OCTET' => 69,
			'FLOAT' => 71,
			'WSTRING' => 84,
			'UNSIGNED' => 60,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'wide_string_type' => 186,
			'integer_type' => 77,
			'boolean_type' => 78,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 182,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'signed_short_int' => 83,
			'string_type' => 183,
			'op_type_spec' => 188,
			'base_type_spec' => 184,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'unsigned_long_int' => 90,
			'param_type_spec' => 185,
			'unsigned_short_int' => 70,
			'fixed_pt_type' => 189,
			'signed_longlong_int' => 72
		}
	},
	{#State 128
		ACTIONS => {
			'error' => 191,
			";" => 190
		}
	},
	{#State 129
		DEFAULT => -244
	},
	{#State 130
		ACTIONS => {
			'ATTRIBUTE' => 192
		}
	},
	{#State 131
		ACTIONS => {
			"}" => 193
		}
	},
	{#State 132
		DEFAULT => -24
	},
	{#State 133
		ACTIONS => {
			'error' => 195,
			";" => 194
		}
	},
	{#State 134
		DEFAULT => -32
	},
	{#State 135
		ACTIONS => {
			'ONEWAY' => 126,
			'NATIVE' => 2,
			'STRUCT' => 6,
			'TYPEDEF' => 12,
			'UNION' => 17,
			'READONLY' => 137,
			'ATTRIBUTE' => -228,
			'CONST' => 23,
			"}" => -33,
			'EXCEPTION' => 24,
			'ENUM' => 29
		},
		DEFAULT => -245,
		GOTOS => {
			'const_dcl' => 133,
			'op_mod' => 127,
			'except_dcl' => 128,
			'op_attribute' => 129,
			'attr_mod' => 130,
			'exports' => 196,
			'export' => 135,
			'struct_type' => 9,
			'op_header' => 136,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'enum_type' => 18,
			'op_dcl' => 138,
			'enum_header' => 21,
			'attr_dcl' => 139,
			'type_dcl' => 140,
			'union_header' => 25
		}
	},
	{#State 136
		ACTIONS => {
			'error' => 198,
			"(" => 197
		},
		GOTOS => {
			'parameter_dcls' => 199
		}
	},
	{#State 137
		DEFAULT => -227
	},
	{#State 138
		ACTIONS => {
			'error' => 201,
			";" => 200
		}
	},
	{#State 139
		ACTIONS => {
			'error' => 203,
			";" => 202
		}
	},
	{#State 140
		ACTIONS => {
			'error' => 205,
			";" => 204
		}
	},
	{#State 141
		ACTIONS => {
			"}" => 206
		}
	},
	{#State 142
		ACTIONS => {
			"}" => 207
		}
	},
	{#State 143
		ACTIONS => {
			"}" => 208
		}
	},
	{#State 144
		ACTIONS => {
			'IDENTIFIER' => 160
		},
		GOTOS => {
			'declarators' => 209,
			'declarator' => 155,
			'simple_declarator' => 158,
			'array_declarator' => 159,
			'complex_declarator' => 157
		}
	},
	{#State 145
		ACTIONS => {
			"}" => 210
		}
	},
	{#State 146
		ACTIONS => {
			"}" => 211
		}
	},
	{#State 147
		DEFAULT => -231
	},
	{#State 148
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 79,
			'LONG' => 80,
			'STRING' => 81,
			"::" => 82,
			'WSTRING' => 84,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'IDENTIFIER' => 88,
			'UNION' => 17,
			'WCHAR' => 63,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		DEFAULT => -171,
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'type_spec' => 144,
			'string_type' => 61,
			'struct_header' => 13,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'enum_type' => 67,
			'enum_header' => 21,
			'member_list' => 212,
			'union_header' => 25,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72,
			'wide_string_type' => 76,
			'boolean_type' => 78,
			'integer_type' => 77,
			'signed_short_int' => 83,
			'member' => 148,
			'struct_type' => 85,
			'union_type' => 87,
			'sequence_type' => 89,
			'unsigned_long_int' => 90,
			'template_type_spec' => 91,
			'constr_type_spec' => 92,
			'simple_type_spec' => 93,
			'fixed_pt_type' => 94
		}
	},
	{#State 149
		DEFAULT => -279
	},
	{#State 150
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'CHARACTER_LITERAL' => 213,
			'WIDE_CHARACTER_LITERAL' => 214,
			"::" => 82,
			'INTEGER_LITERAL' => 234,
			"(" => 218,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'FIXED_PT_LITERAL' => 237,
			"+" => 238,
			'error' => 222,
			"-" => 240,
			'WIDE_STRING_LITERAL' => 226,
			'FALSE' => 225,
			"~" => 241,
			'TRUE' => 228
		},
		GOTOS => {
			'string_literal' => 230,
			'primary_expr' => 232,
			'and_expr' => 233,
			'scoped_name' => 215,
			'positive_int_const' => 216,
			'wide_string_literal' => 217,
			'boolean_literal' => 219,
			'mult_expr' => 235,
			'const_exp' => 220,
			'or_expr' => 221,
			'unary_expr' => 239,
			'xor_expr' => 223,
			'shift_expr' => 224,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 151
		DEFAULT => -212
	},
	{#State 152
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'SEQUENCE' => 51,
			'DOUBLE' => 79,
			'LONG' => 80,
			'STRING' => 81,
			"::" => 82,
			'WSTRING' => 84,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'IDENTIFIER' => 88,
			'WCHAR' => 63,
			'error' => 243,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'wide_string_type' => 76,
			'integer_type' => 77,
			'boolean_type' => 78,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'signed_short_int' => 83,
			'string_type' => 61,
			'sequence_type' => 89,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'unsigned_long_int' => 90,
			'template_type_spec' => 91,
			'unsigned_short_int' => 70,
			'simple_type_spec' => 244,
			'fixed_pt_type' => 94,
			'signed_longlong_int' => 72
		}
	},
	{#State 153
		ACTIONS => {
			'error' => 245,
			'IDENTIFIER' => 246
		}
	},
	{#State 154
		DEFAULT => -117
	},
	{#State 155
		ACTIONS => {
			"," => 247
		},
		DEFAULT => -139
	},
	{#State 156
		DEFAULT => -118
	},
	{#State 157
		DEFAULT => -142
	},
	{#State 158
		DEFAULT => -141
	},
	{#State 159
		DEFAULT => -144
	},
	{#State 160
		ACTIONS => {
			"[" => 250
		},
		DEFAULT => -143,
		GOTOS => {
			'fixed_array_sizes' => 248,
			'fixed_array_size' => 249
		}
	},
	{#State 161
		DEFAULT => -159
	},
	{#State 162
		ACTIONS => {
			'LONG' => 251
		},
		DEFAULT => -160
	},
	{#State 163
		DEFAULT => -147
	},
	{#State 164
		DEFAULT => -155
	},
	{#State 165
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'CHARACTER_LITERAL' => 213,
			'WIDE_CHARACTER_LITERAL' => 214,
			"::" => 82,
			'INTEGER_LITERAL' => 234,
			"(" => 218,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'FIXED_PT_LITERAL' => 237,
			"+" => 238,
			'error' => 253,
			"-" => 240,
			'WIDE_STRING_LITERAL' => 226,
			'FALSE' => 225,
			"~" => 241,
			'TRUE' => 228
		},
		GOTOS => {
			'string_literal' => 230,
			'primary_expr' => 232,
			'and_expr' => 233,
			'scoped_name' => 215,
			'positive_int_const' => 252,
			'wide_string_literal' => 217,
			'boolean_literal' => 219,
			'mult_expr' => 235,
			'const_exp' => 220,
			'or_expr' => 221,
			'unary_expr' => 239,
			'xor_expr' => 223,
			'shift_expr' => 224,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 166
		DEFAULT => -52
	},
	{#State 167
		DEFAULT => -51
	},
	{#State 168
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'CHARACTER_LITERAL' => 213,
			'WIDE_CHARACTER_LITERAL' => 214,
			"::" => 82,
			'INTEGER_LITERAL' => 234,
			"(" => 218,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'FIXED_PT_LITERAL' => 237,
			"+" => 238,
			'error' => 255,
			"-" => 240,
			'WIDE_STRING_LITERAL' => 226,
			'FALSE' => 225,
			"~" => 241,
			'TRUE' => 228
		},
		GOTOS => {
			'string_literal' => 230,
			'primary_expr' => 232,
			'and_expr' => 233,
			'scoped_name' => 215,
			'positive_int_const' => 254,
			'wide_string_literal' => 217,
			'boolean_literal' => 219,
			'mult_expr' => 235,
			'const_exp' => 220,
			'or_expr' => 221,
			'unary_expr' => 239,
			'xor_expr' => 223,
			'shift_expr' => 224,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 169
		ACTIONS => {
			"}" => 256
		}
	},
	{#State 170
		ACTIONS => {
			"}" => 257
		}
	},
	{#State 171
		DEFAULT => -16
	},
	{#State 172
		ACTIONS => {
			"}" => 258
		}
	},
	{#State 173
		ACTIONS => {
			";" => 259,
			"," => 260
		},
		DEFAULT => -203
	},
	{#State 174
		DEFAULT => -207
	},
	{#State 175
		ACTIONS => {
			"}" => 261
		}
	},
	{#State 176
		DEFAULT => -58
	},
	{#State 177
		ACTIONS => {
			'error' => 262,
			"=" => 263
		}
	},
	{#State 178
		ACTIONS => {
			'CHAR' => 74,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'IDENTIFIER' => 88,
			'error' => 267,
			'LONG' => 271,
			"::" => 82,
			'ENUM' => 29,
			'UNSIGNED' => 60
		},
		GOTOS => {
			'switch_type_spec' => 268,
			'unsigned_int' => 47,
			'signed_int' => 50,
			'integer_type' => 270,
			'boolean_type' => 269,
			'unsigned_longlong_int' => 64,
			'char_type' => 264,
			'enum_type' => 266,
			'unsigned_long_int' => 90,
			'scoped_name' => 265,
			'enum_header' => 21,
			'signed_long_int' => 57,
			'unsigned_short_int' => 70,
			'signed_short_int' => 83,
			'signed_longlong_int' => 72
		}
	},
	{#State 179
		DEFAULT => -179
	},
	{#State 180
		ACTIONS => {
			'error' => 273,
			'IDENTIFIER' => 88,
			"::" => 82
		},
		GOTOS => {
			'scoped_name' => 272,
			'interface_names' => 275,
			'interface_name' => 274
		}
	},
	{#State 181
		DEFAULT => -30
	},
	{#State 182
		ACTIONS => {
			"::" => 153
		},
		DEFAULT => -275
	},
	{#State 183
		DEFAULT => -272
	},
	{#State 184
		DEFAULT => -271
	},
	{#State 185
		DEFAULT => -247
	},
	{#State 186
		DEFAULT => -273
	},
	{#State 187
		DEFAULT => -248
	},
	{#State 188
		ACTIONS => {
			'error' => 276,
			'IDENTIFIER' => 277
		}
	},
	{#State 189
		DEFAULT => -274
	},
	{#State 190
		DEFAULT => -37
	},
	{#State 191
		DEFAULT => -42
	},
	{#State 192
		ACTIONS => {
			'CHAR' => 74,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'OBJECT' => 75,
			'IDENTIFIER' => 88,
			'FIXED' => 49,
			'WCHAR' => 63,
			'DOUBLE' => 79,
			'error' => 278,
			'LONG' => 80,
			'STRING' => 81,
			"::" => 82,
			'OCTET' => 69,
			'FLOAT' => 71,
			'WSTRING' => 84,
			'UNSIGNED' => 60,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'wide_string_type' => 186,
			'integer_type' => 77,
			'boolean_type' => 78,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 182,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'signed_short_int' => 83,
			'string_type' => 183,
			'base_type_spec' => 184,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'unsigned_long_int' => 90,
			'param_type_spec' => 279,
			'unsigned_short_int' => 70,
			'fixed_pt_type' => 189,
			'signed_longlong_int' => 72
		}
	},
	{#State 193
		DEFAULT => -26
	},
	{#State 194
		DEFAULT => -36
	},
	{#State 195
		DEFAULT => -41
	},
	{#State 196
		DEFAULT => -34
	},
	{#State 197
		ACTIONS => {
			'error' => 281,
			")" => 285,
			'OUT' => 286,
			'INOUT' => 282,
			'IN' => 280
		},
		GOTOS => {
			'param_dcl' => 287,
			'param_dcls' => 284,
			'param_attribute' => 283
		}
	},
	{#State 198
		DEFAULT => -241
	},
	{#State 199
		ACTIONS => {
			'RAISES' => 291,
			'CONTEXT' => 288
		},
		DEFAULT => -237,
		GOTOS => {
			'context_expr' => 290,
			'raises_expr' => 289
		}
	},
	{#State 200
		DEFAULT => -39
	},
	{#State 201
		DEFAULT => -44
	},
	{#State 202
		DEFAULT => -38
	},
	{#State 203
		DEFAULT => -43
	},
	{#State 204
		DEFAULT => -35
	},
	{#State 205
		DEFAULT => -40
	},
	{#State 206
		DEFAULT => -25
	},
	{#State 207
		DEFAULT => -18
	},
	{#State 208
		DEFAULT => -17
	},
	{#State 209
		ACTIONS => {
			'error' => 293,
			";" => 292
		}
	},
	{#State 210
		DEFAULT => -233
	},
	{#State 211
		DEFAULT => -232
	},
	{#State 212
		DEFAULT => -172
	},
	{#State 213
		DEFAULT => -98
	},
	{#State 214
		DEFAULT => -99
	},
	{#State 215
		ACTIONS => {
			"::" => 153
		},
		DEFAULT => -91
	},
	{#State 216
		ACTIONS => {
			"," => 294
		}
	},
	{#State 217
		DEFAULT => -97
	},
	{#State 218
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'CHARACTER_LITERAL' => 213,
			'WIDE_CHARACTER_LITERAL' => 214,
			"::" => 82,
			'INTEGER_LITERAL' => 234,
			"(" => 218,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'FIXED_PT_LITERAL' => 237,
			"+" => 238,
			'error' => 296,
			"-" => 240,
			'WIDE_STRING_LITERAL' => 226,
			'FALSE' => 225,
			"~" => 241,
			'TRUE' => 228
		},
		GOTOS => {
			'mult_expr' => 235,
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'const_exp' => 295,
			'and_expr' => 233,
			'or_expr' => 221,
			'unary_expr' => 239,
			'scoped_name' => 215,
			'xor_expr' => 223,
			'shift_expr' => 224,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 219
		DEFAULT => -102
	},
	{#State 220
		DEFAULT => -109
	},
	{#State 221
		ACTIONS => {
			"|" => 297
		},
		DEFAULT => -69
	},
	{#State 222
		ACTIONS => {
			">" => 298
		}
	},
	{#State 223
		ACTIONS => {
			"^" => 299
		},
		DEFAULT => -70
	},
	{#State 224
		ACTIONS => {
			"<<" => 300,
			">>" => 301
		},
		DEFAULT => -74
	},
	{#State 225
		DEFAULT => -108
	},
	{#State 226
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 226
		},
		DEFAULT => -105,
		GOTOS => {
			'wide_string_literal' => 302
		}
	},
	{#State 227
		DEFAULT => -92
	},
	{#State 228
		DEFAULT => -107
	},
	{#State 229
		ACTIONS => {
			"+" => 303,
			"-" => 304
		},
		DEFAULT => -76
	},
	{#State 230
		DEFAULT => -96
	},
	{#State 231
		DEFAULT => -101
	},
	{#State 232
		DEFAULT => -87
	},
	{#State 233
		ACTIONS => {
			"&" => 305
		},
		DEFAULT => -72
	},
	{#State 234
		DEFAULT => -95
	},
	{#State 235
		ACTIONS => {
			"%" => 307,
			"*" => 306,
			"/" => 308
		},
		DEFAULT => -79
	},
	{#State 236
		ACTIONS => {
			'STRING_LITERAL' => 236
		},
		DEFAULT => -103,
		GOTOS => {
			'string_literal' => 309
		}
	},
	{#State 237
		DEFAULT => -100
	},
	{#State 238
		DEFAULT => -89
	},
	{#State 239
		DEFAULT => -82
	},
	{#State 240
		DEFAULT => -88
	},
	{#State 241
		DEFAULT => -90
	},
	{#State 242
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'string_literal' => 230,
			'boolean_literal' => 219,
			'scoped_name' => 215,
			'primary_expr' => 310,
			'literal' => 227,
			'wide_string_literal' => 217
		}
	},
	{#State 243
		ACTIONS => {
			">" => 311
		}
	},
	{#State 244
		ACTIONS => {
			">" => 313,
			"," => 312
		}
	},
	{#State 245
		DEFAULT => -54
	},
	{#State 246
		DEFAULT => -53
	},
	{#State 247
		ACTIONS => {
			'IDENTIFIER' => 160
		},
		GOTOS => {
			'declarators' => 314,
			'declarator' => 155,
			'simple_declarator' => 158,
			'array_declarator' => 159,
			'complex_declarator' => 157
		}
	},
	{#State 248
		DEFAULT => -219
	},
	{#State 249
		ACTIONS => {
			"[" => 250
		},
		DEFAULT => -220,
		GOTOS => {
			'fixed_array_sizes' => 315,
			'fixed_array_size' => 249
		}
	},
	{#State 250
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'CHARACTER_LITERAL' => 213,
			'WIDE_CHARACTER_LITERAL' => 214,
			"::" => 82,
			'INTEGER_LITERAL' => 234,
			"(" => 218,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'FIXED_PT_LITERAL' => 237,
			"+" => 238,
			'error' => 317,
			"-" => 240,
			'WIDE_STRING_LITERAL' => 226,
			'FALSE' => 225,
			"~" => 241,
			'TRUE' => 228
		},
		GOTOS => {
			'string_literal' => 230,
			'primary_expr' => 232,
			'and_expr' => 233,
			'scoped_name' => 215,
			'positive_int_const' => 316,
			'wide_string_literal' => 217,
			'boolean_literal' => 219,
			'mult_expr' => 235,
			'const_exp' => 220,
			'or_expr' => 221,
			'unary_expr' => 239,
			'xor_expr' => 223,
			'shift_expr' => 224,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 251
		DEFAULT => -161
	},
	{#State 252
		ACTIONS => {
			">" => 318
		}
	},
	{#State 253
		ACTIONS => {
			">" => 319
		}
	},
	{#State 254
		ACTIONS => {
			">" => 320
		}
	},
	{#State 255
		ACTIONS => {
			">" => 321
		}
	},
	{#State 256
		DEFAULT => -169
	},
	{#State 257
		DEFAULT => -168
	},
	{#State 258
		DEFAULT => -199
	},
	{#State 259
		DEFAULT => -206
	},
	{#State 260
		ACTIONS => {
			'IDENTIFIER' => 174
		},
		DEFAULT => -205,
		GOTOS => {
			'enumerators' => 322,
			'enumerator' => 173
		}
	},
	{#State 261
		DEFAULT => -198
	},
	{#State 262
		DEFAULT => -57
	},
	{#State 263
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'CHARACTER_LITERAL' => 213,
			'WIDE_CHARACTER_LITERAL' => 214,
			"::" => 82,
			'INTEGER_LITERAL' => 234,
			"(" => 218,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'FIXED_PT_LITERAL' => 237,
			"+" => 238,
			'error' => 324,
			"-" => 240,
			'WIDE_STRING_LITERAL' => 226,
			'FALSE' => 225,
			"~" => 241,
			'TRUE' => 228
		},
		GOTOS => {
			'mult_expr' => 235,
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'const_exp' => 323,
			'and_expr' => 233,
			'or_expr' => 221,
			'unary_expr' => 239,
			'scoped_name' => 215,
			'xor_expr' => 223,
			'shift_expr' => 224,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 264
		DEFAULT => -182
	},
	{#State 265
		ACTIONS => {
			"::" => 153
		},
		DEFAULT => -185
	},
	{#State 266
		DEFAULT => -184
	},
	{#State 267
		ACTIONS => {
			")" => 325
		}
	},
	{#State 268
		ACTIONS => {
			")" => 326
		}
	},
	{#State 269
		DEFAULT => -183
	},
	{#State 270
		DEFAULT => -181
	},
	{#State 271
		ACTIONS => {
			'LONG' => 164
		},
		DEFAULT => -154
	},
	{#State 272
		ACTIONS => {
			"::" => 153
		},
		DEFAULT => -49
	},
	{#State 273
		DEFAULT => -46
	},
	{#State 274
		ACTIONS => {
			"," => 327
		},
		DEFAULT => -47
	},
	{#State 275
		DEFAULT => -45
	},
	{#State 276
		DEFAULT => -243
	},
	{#State 277
		DEFAULT => -242
	},
	{#State 278
		DEFAULT => -226
	},
	{#State 279
		ACTIONS => {
			'error' => 328,
			'IDENTIFIER' => 34
		},
		GOTOS => {
			'simple_declarators' => 330,
			'simple_declarator' => 329
		}
	},
	{#State 280
		DEFAULT => -257
	},
	{#State 281
		ACTIONS => {
			")" => 331
		}
	},
	{#State 282
		DEFAULT => -259
	},
	{#State 283
		ACTIONS => {
			'CHAR' => 74,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'OBJECT' => 75,
			'IDENTIFIER' => 88,
			'FIXED' => 49,
			'WCHAR' => 63,
			'DOUBLE' => 79,
			'LONG' => 80,
			'STRING' => 81,
			"::" => 82,
			'OCTET' => 69,
			'FLOAT' => 71,
			'WSTRING' => 84,
			'UNSIGNED' => 60,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'wide_string_type' => 186,
			'integer_type' => 77,
			'boolean_type' => 78,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 182,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'signed_short_int' => 83,
			'string_type' => 183,
			'base_type_spec' => 184,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'unsigned_long_int' => 90,
			'param_type_spec' => 332,
			'unsigned_short_int' => 70,
			'fixed_pt_type' => 189,
			'signed_longlong_int' => 72
		}
	},
	{#State 284
		ACTIONS => {
			")" => 333
		}
	},
	{#State 285
		DEFAULT => -250
	},
	{#State 286
		DEFAULT => -258
	},
	{#State 287
		ACTIONS => {
			";" => 334,
			"," => 335
		},
		DEFAULT => -252
	},
	{#State 288
		ACTIONS => {
			'error' => 337,
			"(" => 336
		}
	},
	{#State 289
		ACTIONS => {
			'CONTEXT' => 288
		},
		DEFAULT => -238,
		GOTOS => {
			'context_expr' => 338
		}
	},
	{#State 290
		DEFAULT => -240
	},
	{#State 291
		ACTIONS => {
			'error' => 340,
			"(" => 339
		}
	},
	{#State 292
		DEFAULT => -173
	},
	{#State 293
		DEFAULT => -174
	},
	{#State 294
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'CHARACTER_LITERAL' => 213,
			'WIDE_CHARACTER_LITERAL' => 214,
			"::" => 82,
			'INTEGER_LITERAL' => 234,
			"(" => 218,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'FIXED_PT_LITERAL' => 237,
			"+" => 238,
			'error' => 342,
			"-" => 240,
			'WIDE_STRING_LITERAL' => 226,
			'FALSE' => 225,
			"~" => 241,
			'TRUE' => 228
		},
		GOTOS => {
			'string_literal' => 230,
			'primary_expr' => 232,
			'and_expr' => 233,
			'scoped_name' => 215,
			'positive_int_const' => 341,
			'wide_string_literal' => 217,
			'boolean_literal' => 219,
			'mult_expr' => 235,
			'const_exp' => 220,
			'or_expr' => 221,
			'unary_expr' => 239,
			'xor_expr' => 223,
			'shift_expr' => 224,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 295
		ACTIONS => {
			")" => 343
		}
	},
	{#State 296
		ACTIONS => {
			")" => 344
		}
	},
	{#State 297
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			"+" => 238,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"-" => 240,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"~" => 241,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'mult_expr' => 235,
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'and_expr' => 233,
			'unary_expr' => 239,
			'scoped_name' => 215,
			'xor_expr' => 345,
			'shift_expr' => 224,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 298
		DEFAULT => -278
	},
	{#State 299
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			"+" => 238,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"-" => 240,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"~" => 241,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'mult_expr' => 235,
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'and_expr' => 346,
			'unary_expr' => 239,
			'scoped_name' => 215,
			'shift_expr' => 224,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 300
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			"+" => 238,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"-" => 240,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"~" => 241,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'mult_expr' => 235,
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'unary_expr' => 239,
			'scoped_name' => 215,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 347
		}
	},
	{#State 301
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			"+" => 238,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"-" => 240,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"~" => 241,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'mult_expr' => 235,
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'unary_expr' => 239,
			'scoped_name' => 215,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 348
		}
	},
	{#State 302
		DEFAULT => -106
	},
	{#State 303
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			"+" => 238,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"-" => 240,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"~" => 241,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'mult_expr' => 349,
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'unary_expr' => 239,
			'scoped_name' => 215,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242
		}
	},
	{#State 304
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			"+" => 238,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"-" => 240,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"~" => 241,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'mult_expr' => 350,
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'unary_expr' => 239,
			'scoped_name' => 215,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242
		}
	},
	{#State 305
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			"+" => 238,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"-" => 240,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"~" => 241,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'mult_expr' => 235,
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'unary_expr' => 239,
			'scoped_name' => 215,
			'shift_expr' => 351,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 306
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			"+" => 238,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"-" => 240,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"~" => 241,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'unary_expr' => 352,
			'scoped_name' => 215,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242
		}
	},
	{#State 307
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			"+" => 238,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"-" => 240,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"~" => 241,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'unary_expr' => 353,
			'scoped_name' => 215,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242
		}
	},
	{#State 308
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'CHARACTER_LITERAL' => 213,
			"+" => 238,
			'FIXED_PT_LITERAL' => 237,
			'WIDE_CHARACTER_LITERAL' => 214,
			"-" => 240,
			"::" => 82,
			'FALSE' => 225,
			'WIDE_STRING_LITERAL' => 226,
			'INTEGER_LITERAL' => 234,
			"~" => 241,
			"(" => 218,
			'TRUE' => 228
		},
		GOTOS => {
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'unary_expr' => 354,
			'scoped_name' => 215,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242
		}
	},
	{#State 309
		DEFAULT => -104
	},
	{#State 310
		DEFAULT => -86
	},
	{#State 311
		DEFAULT => -211
	},
	{#State 312
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'CHARACTER_LITERAL' => 213,
			'WIDE_CHARACTER_LITERAL' => 214,
			"::" => 82,
			'INTEGER_LITERAL' => 234,
			"(" => 218,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'FIXED_PT_LITERAL' => 237,
			"+" => 238,
			'error' => 356,
			"-" => 240,
			'WIDE_STRING_LITERAL' => 226,
			'FALSE' => 225,
			"~" => 241,
			'TRUE' => 228
		},
		GOTOS => {
			'string_literal' => 230,
			'primary_expr' => 232,
			'and_expr' => 233,
			'scoped_name' => 215,
			'positive_int_const' => 355,
			'wide_string_literal' => 217,
			'boolean_literal' => 219,
			'mult_expr' => 235,
			'const_exp' => 220,
			'or_expr' => 221,
			'unary_expr' => 239,
			'xor_expr' => 223,
			'shift_expr' => 224,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 313
		DEFAULT => -210
	},
	{#State 314
		DEFAULT => -140
	},
	{#State 315
		DEFAULT => -221
	},
	{#State 316
		ACTIONS => {
			"]" => 357
		}
	},
	{#State 317
		ACTIONS => {
			"]" => 358
		}
	},
	{#State 318
		DEFAULT => -213
	},
	{#State 319
		DEFAULT => -215
	},
	{#State 320
		DEFAULT => -216
	},
	{#State 321
		DEFAULT => -218
	},
	{#State 322
		DEFAULT => -204
	},
	{#State 323
		DEFAULT => -55
	},
	{#State 324
		DEFAULT => -56
	},
	{#State 325
		DEFAULT => -178
	},
	{#State 326
		ACTIONS => {
			"{" => 360,
			'error' => 359
		}
	},
	{#State 327
		ACTIONS => {
			'IDENTIFIER' => 88,
			"::" => 82
		},
		GOTOS => {
			'scoped_name' => 272,
			'interface_names' => 361,
			'interface_name' => 274
		}
	},
	{#State 328
		DEFAULT => -225
	},
	{#State 329
		ACTIONS => {
			"," => 362
		},
		DEFAULT => -229
	},
	{#State 330
		DEFAULT => -224
	},
	{#State 331
		DEFAULT => -251
	},
	{#State 332
		ACTIONS => {
			'IDENTIFIER' => 34
		},
		GOTOS => {
			'simple_declarator' => 363
		}
	},
	{#State 333
		DEFAULT => -249
	},
	{#State 334
		DEFAULT => -255
	},
	{#State 335
		ACTIONS => {
			'OUT' => 286,
			'INOUT' => 282,
			'IN' => 280
		},
		DEFAULT => -254,
		GOTOS => {
			'param_dcl' => 287,
			'param_dcls' => 364,
			'param_attribute' => 283
		}
	},
	{#State 336
		ACTIONS => {
			'error' => 365,
			'STRING_LITERAL' => 236
		},
		GOTOS => {
			'string_literal' => 366,
			'string_literals' => 367
		}
	},
	{#State 337
		DEFAULT => -268
	},
	{#State 338
		DEFAULT => -239
	},
	{#State 339
		ACTIONS => {
			'error' => 369,
			'IDENTIFIER' => 88,
			"::" => 82
		},
		GOTOS => {
			'scoped_name' => 368,
			'exception_names' => 370,
			'exception_name' => 371
		}
	},
	{#State 340
		DEFAULT => -262
	},
	{#State 341
		ACTIONS => {
			">" => 372
		}
	},
	{#State 342
		ACTIONS => {
			">" => 373
		}
	},
	{#State 343
		DEFAULT => -93
	},
	{#State 344
		DEFAULT => -94
	},
	{#State 345
		ACTIONS => {
			"^" => 299
		},
		DEFAULT => -71
	},
	{#State 346
		ACTIONS => {
			"&" => 305
		},
		DEFAULT => -73
	},
	{#State 347
		ACTIONS => {
			"+" => 303,
			"-" => 304
		},
		DEFAULT => -78
	},
	{#State 348
		ACTIONS => {
			"+" => 303,
			"-" => 304
		},
		DEFAULT => -77
	},
	{#State 349
		ACTIONS => {
			"%" => 307,
			"*" => 306,
			"/" => 308
		},
		DEFAULT => -80
	},
	{#State 350
		ACTIONS => {
			"%" => 307,
			"*" => 306,
			"/" => 308
		},
		DEFAULT => -81
	},
	{#State 351
		ACTIONS => {
			"<<" => 300,
			">>" => 301
		},
		DEFAULT => -75
	},
	{#State 352
		DEFAULT => -83
	},
	{#State 353
		DEFAULT => -85
	},
	{#State 354
		DEFAULT => -84
	},
	{#State 355
		ACTIONS => {
			">" => 374
		}
	},
	{#State 356
		ACTIONS => {
			">" => 375
		}
	},
	{#State 357
		DEFAULT => -222
	},
	{#State 358
		DEFAULT => -223
	},
	{#State 359
		DEFAULT => -177
	},
	{#State 360
		ACTIONS => {
			'error' => 379,
			'CASE' => 376,
			'DEFAULT' => 378
		},
		GOTOS => {
			'case_labels' => 381,
			'switch_body' => 380,
			'case' => 377,
			'case_label' => 382
		}
	},
	{#State 361
		DEFAULT => -48
	},
	{#State 362
		ACTIONS => {
			'IDENTIFIER' => 34
		},
		GOTOS => {
			'simple_declarators' => 383,
			'simple_declarator' => 329
		}
	},
	{#State 363
		DEFAULT => -256
	},
	{#State 364
		DEFAULT => -253
	},
	{#State 365
		ACTIONS => {
			")" => 384
		}
	},
	{#State 366
		ACTIONS => {
			"," => 385
		},
		DEFAULT => -269
	},
	{#State 367
		ACTIONS => {
			")" => 386
		}
	},
	{#State 368
		ACTIONS => {
			"::" => 153
		},
		DEFAULT => -265
	},
	{#State 369
		ACTIONS => {
			")" => 387
		}
	},
	{#State 370
		ACTIONS => {
			")" => 388
		}
	},
	{#State 371
		ACTIONS => {
			"," => 389
		},
		DEFAULT => -263
	},
	{#State 372
		DEFAULT => -276
	},
	{#State 373
		DEFAULT => -277
	},
	{#State 374
		DEFAULT => -208
	},
	{#State 375
		DEFAULT => -209
	},
	{#State 376
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 231,
			'CHARACTER_LITERAL' => 213,
			'WIDE_CHARACTER_LITERAL' => 214,
			"::" => 82,
			'INTEGER_LITERAL' => 234,
			"(" => 218,
			'IDENTIFIER' => 88,
			'STRING_LITERAL' => 236,
			'FIXED_PT_LITERAL' => 237,
			"+" => 238,
			'error' => 391,
			"-" => 240,
			'WIDE_STRING_LITERAL' => 226,
			'FALSE' => 225,
			"~" => 241,
			'TRUE' => 228
		},
		GOTOS => {
			'mult_expr' => 235,
			'string_literal' => 230,
			'boolean_literal' => 219,
			'primary_expr' => 232,
			'const_exp' => 390,
			'and_expr' => 233,
			'or_expr' => 221,
			'unary_expr' => 239,
			'scoped_name' => 215,
			'xor_expr' => 223,
			'shift_expr' => 224,
			'wide_string_literal' => 217,
			'literal' => 227,
			'unary_operator' => 242,
			'add_expr' => 229
		}
	},
	{#State 377
		ACTIONS => {
			'CASE' => 376,
			'DEFAULT' => 378
		},
		DEFAULT => -186,
		GOTOS => {
			'case_labels' => 381,
			'switch_body' => 392,
			'case' => 377,
			'case_label' => 382
		}
	},
	{#State 378
		ACTIONS => {
			'error' => 393,
			":" => 394
		}
	},
	{#State 379
		ACTIONS => {
			"}" => 395
		}
	},
	{#State 380
		ACTIONS => {
			"}" => 396
		}
	},
	{#State 381
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 79,
			'LONG' => 80,
			'STRING' => 81,
			"::" => 82,
			'WSTRING' => 84,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 86,
			'IDENTIFIER' => 88,
			'UNION' => 17,
			'WCHAR' => 63,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'type_spec' => 397,
			'string_type' => 61,
			'struct_header' => 13,
			'element_spec' => 398,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'enum_type' => 67,
			'enum_header' => 21,
			'union_header' => 25,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72,
			'wide_string_type' => 76,
			'boolean_type' => 78,
			'integer_type' => 77,
			'signed_short_int' => 83,
			'struct_type' => 85,
			'union_type' => 87,
			'sequence_type' => 89,
			'unsigned_long_int' => 90,
			'template_type_spec' => 91,
			'constr_type_spec' => 92,
			'simple_type_spec' => 93,
			'fixed_pt_type' => 94
		}
	},
	{#State 382
		ACTIONS => {
			'CASE' => 376,
			'DEFAULT' => 378
		},
		DEFAULT => -190,
		GOTOS => {
			'case_labels' => 399,
			'case_label' => 382
		}
	},
	{#State 383
		DEFAULT => -230
	},
	{#State 384
		DEFAULT => -267
	},
	{#State 385
		ACTIONS => {
			'STRING_LITERAL' => 236
		},
		GOTOS => {
			'string_literal' => 366,
			'string_literals' => 400
		}
	},
	{#State 386
		DEFAULT => -266
	},
	{#State 387
		DEFAULT => -261
	},
	{#State 388
		DEFAULT => -260
	},
	{#State 389
		ACTIONS => {
			'IDENTIFIER' => 88,
			"::" => 82
		},
		GOTOS => {
			'scoped_name' => 368,
			'exception_names' => 401,
			'exception_name' => 371
		}
	},
	{#State 390
		ACTIONS => {
			'error' => 402,
			":" => 403
		}
	},
	{#State 391
		DEFAULT => -194
	},
	{#State 392
		DEFAULT => -187
	},
	{#State 393
		DEFAULT => -196
	},
	{#State 394
		DEFAULT => -195
	},
	{#State 395
		DEFAULT => -176
	},
	{#State 396
		DEFAULT => -175
	},
	{#State 397
		ACTIONS => {
			'IDENTIFIER' => 160
		},
		GOTOS => {
			'declarator' => 404,
			'simple_declarator' => 158,
			'array_declarator' => 159,
			'complex_declarator' => 157
		}
	},
	{#State 398
		ACTIONS => {
			'error' => 406,
			";" => 405
		}
	},
	{#State 399
		DEFAULT => -191
	},
	{#State 400
		DEFAULT => -270
	},
	{#State 401
		DEFAULT => -264
	},
	{#State 402
		DEFAULT => -193
	},
	{#State 403
		DEFAULT => -192
	},
	{#State 404
		DEFAULT => -197
	},
	{#State 405
		DEFAULT => -188
	},
	{#State 406
		DEFAULT => -189
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
#line 60 "parser22.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 0,
sub
#line 66 "parser22.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 70 "parser22.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 77 "parser22.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 81 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
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
#line 100 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 12
		 'definition', 2,
sub
#line 106 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 112 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 118 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 124 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'definition', 3,
sub
#line 130 "parser22.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 17
		 'module', 4,
sub
#line 143 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 18
		 'module', 4,
sub
#line 150 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 19
		 'module', 2,
sub
#line 156 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 165 "parser22.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 21
		 'module_header', 2,
sub
#line 171 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 22
		 'interface', 1, undef
	],
	[#Rule 23
		 'interface', 1, undef
	],
	[#Rule 24
		 'interface_dcl', 3,
sub
#line 188 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 25
		 'interface_dcl', 4,
sub
#line 196 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 26
		 'interface_dcl', 4,
sub
#line 204 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 27
		 'forward_dcl', 2,
sub
#line 215 "parser22.yp"
{
			new ForwardRegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 28
		 'forward_dcl', 2,
sub
#line 221 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 29
		 'interface_header', 2,
sub
#line 230 "parser22.yp"
{
			new RegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 30
		 'interface_header', 3,
sub
#line 236 "parser22.yp"
{
			my $inheritance = new InheritanceSpec($_[0],
					'list_interface'		=>	$_[4]
			);
			new RegularInterface($_[0],
					'idf'					=>	$_[3],
					'inheritance'			=>	$inheritance
			);
		}
	],
	[#Rule 31
		 'interface_header', 2,
sub
#line 246 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 32
		 'interface_body', 1, undef
	],
	[#Rule 33
		 'exports', 1,
sub
#line 260 "parser22.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 34
		 'exports', 2,
sub
#line 264 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
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
		 'export', 2, undef
	],
	[#Rule 39
		 'export', 2, undef
	],
	[#Rule 40
		 'export', 2,
sub
#line 283 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 41
		 'export', 2,
sub
#line 289 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 42
		 'export', 2,
sub
#line 295 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 43
		 'export', 2,
sub
#line 301 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 44
		 'export', 2,
sub
#line 307 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 45
		 'interface_inheritance_spec', 2,
sub
#line 317 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 46
		 'interface_inheritance_spec', 2,
sub
#line 321 "parser22.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 47
		 'interface_names', 1,
sub
#line 329 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 48
		 'interface_names', 3,
sub
#line 333 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 49
		 'interface_name', 1,
sub
#line 341 "parser22.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 50
		 'scoped_name', 1, undef
	],
	[#Rule 51
		 'scoped_name', 2,
sub
#line 351 "parser22.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 52
		 'scoped_name', 2,
sub
#line 355 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 53
		 'scoped_name', 3,
sub
#line 361 "parser22.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 54
		 'scoped_name', 3,
sub
#line 365 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 55
		 'const_dcl', 5,
sub
#line 375 "parser22.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 56
		 'const_dcl', 5,
sub
#line 383 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 57
		 'const_dcl', 4,
sub
#line 388 "parser22.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 58
		 'const_dcl', 3,
sub
#line 393 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 59
		 'const_dcl', 2,
sub
#line 398 "parser22.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
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
		 'const_type', 1, undef
	],
	[#Rule 67
		 'const_type', 1, undef
	],
	[#Rule 68
		 'const_type', 1,
sub
#line 423 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 69
		 'const_exp', 1, undef
	],
	[#Rule 70
		 'or_expr', 1, undef
	],
	[#Rule 71
		 'or_expr', 3,
sub
#line 439 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 72
		 'xor_expr', 1, undef
	],
	[#Rule 73
		 'xor_expr', 3,
sub
#line 449 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 74
		 'and_expr', 1, undef
	],
	[#Rule 75
		 'and_expr', 3,
sub
#line 459 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 76
		 'shift_expr', 1, undef
	],
	[#Rule 77
		 'shift_expr', 3,
sub
#line 469 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 78
		 'shift_expr', 3,
sub
#line 473 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 79
		 'add_expr', 1, undef
	],
	[#Rule 80
		 'add_expr', 3,
sub
#line 483 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 81
		 'add_expr', 3,
sub
#line 487 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 82
		 'mult_expr', 1, undef
	],
	[#Rule 83
		 'mult_expr', 3,
sub
#line 497 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 84
		 'mult_expr', 3,
sub
#line 501 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 85
		 'mult_expr', 3,
sub
#line 505 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 86
		 'unary_expr', 2,
sub
#line 513 "parser22.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 87
		 'unary_expr', 1, undef
	],
	[#Rule 88
		 'unary_operator', 1, undef
	],
	[#Rule 89
		 'unary_operator', 1, undef
	],
	[#Rule 90
		 'unary_operator', 1, undef
	],
	[#Rule 91
		 'primary_expr', 1,
sub
#line 533 "parser22.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 92
		 'primary_expr', 1,
sub
#line 539 "parser22.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 93
		 'primary_expr', 3,
sub
#line 543 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 94
		 'primary_expr', 3,
sub
#line 547 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 95
		 'literal', 1,
sub
#line 556 "parser22.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 96
		 'literal', 1,
sub
#line 563 "parser22.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 97
		 'literal', 1,
sub
#line 569 "parser22.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 98
		 'literal', 1,
sub
#line 575 "parser22.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 99
		 'literal', 1,
sub
#line 581 "parser22.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 100
		 'literal', 1,
sub
#line 587 "parser22.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 101
		 'literal', 1,
sub
#line 594 "parser22.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 102
		 'literal', 1, undef
	],
	[#Rule 103
		 'string_literal', 1, undef
	],
	[#Rule 104
		 'string_literal', 2,
sub
#line 608 "parser22.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 105
		 'wide_string_literal', 1, undef
	],
	[#Rule 106
		 'wide_string_literal', 2,
sub
#line 617 "parser22.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 107
		 'boolean_literal', 1,
sub
#line 625 "parser22.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 108
		 'boolean_literal', 1,
sub
#line 631 "parser22.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 109
		 'positive_int_const', 1,
sub
#line 641 "parser22.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 110
		 'type_dcl', 2,
sub
#line 651 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 111
		 'type_dcl', 1, undef
	],
	[#Rule 112
		 'type_dcl', 1, undef
	],
	[#Rule 113
		 'type_dcl', 1, undef
	],
	[#Rule 114
		 'type_dcl', 2,
sub
#line 661 "parser22.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 115
		 'type_dcl', 2,
sub
#line 668 "parser22.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 116
		 'type_dcl', 2,
sub
#line 673 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 117
		 'type_declarator', 2,
sub
#line 682 "parser22.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 118
		 'type_declarator', 2,
sub
#line 689 "parser22.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 119
		 'type_spec', 1, undef
	],
	[#Rule 120
		 'type_spec', 1, undef
	],
	[#Rule 121
		 'simple_type_spec', 1, undef
	],
	[#Rule 122
		 'simple_type_spec', 1, undef
	],
	[#Rule 123
		 'simple_type_spec', 1,
sub
#line 710 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
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
		 'base_type_spec', 1, undef
	],
	[#Rule 131
		 'base_type_spec', 1, undef
	],
	[#Rule 132
		 'template_type_spec', 1, undef
	],
	[#Rule 133
		 'template_type_spec', 1, undef
	],
	[#Rule 134
		 'template_type_spec', 1, undef
	],
	[#Rule 135
		 'template_type_spec', 1, undef
	],
	[#Rule 136
		 'constr_type_spec', 1, undef
	],
	[#Rule 137
		 'constr_type_spec', 1, undef
	],
	[#Rule 138
		 'constr_type_spec', 1, undef
	],
	[#Rule 139
		 'declarators', 1,
sub
#line 760 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 140
		 'declarators', 3,
sub
#line 764 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 141
		 'declarator', 1,
sub
#line 773 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 142
		 'declarator', 1, undef
	],
	[#Rule 143
		 'simple_declarator', 1, undef
	],
	[#Rule 144
		 'complex_declarator', 1, undef
	],
	[#Rule 145
		 'floating_pt_type', 1,
sub
#line 795 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 146
		 'floating_pt_type', 1,
sub
#line 801 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 147
		 'floating_pt_type', 2,
sub
#line 807 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 148
		 'integer_type', 1, undef
	],
	[#Rule 149
		 'integer_type', 1, undef
	],
	[#Rule 150
		 'signed_int', 1, undef
	],
	[#Rule 151
		 'signed_int', 1, undef
	],
	[#Rule 152
		 'signed_int', 1, undef
	],
	[#Rule 153
		 'signed_short_int', 1,
sub
#line 835 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 154
		 'signed_long_int', 1,
sub
#line 845 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 155
		 'signed_longlong_int', 2,
sub
#line 855 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 156
		 'unsigned_int', 1, undef
	],
	[#Rule 157
		 'unsigned_int', 1, undef
	],
	[#Rule 158
		 'unsigned_int', 1, undef
	],
	[#Rule 159
		 'unsigned_short_int', 2,
sub
#line 875 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 160
		 'unsigned_long_int', 2,
sub
#line 885 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 161
		 'unsigned_longlong_int', 3,
sub
#line 895 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 162
		 'char_type', 1,
sub
#line 905 "parser22.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'wide_char_type', 1,
sub
#line 915 "parser22.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 164
		 'boolean_type', 1,
sub
#line 925 "parser22.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 165
		 'octet_type', 1,
sub
#line 935 "parser22.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 166
		 'any_type', 1,
sub
#line 945 "parser22.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 167
		 'object_type', 1,
sub
#line 955 "parser22.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 168
		 'struct_type', 4,
sub
#line 965 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 169
		 'struct_type', 4,
sub
#line 972 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 170
		 'struct_header', 2,
sub
#line 981 "parser22.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 171
		 'member_list', 1,
sub
#line 991 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 172
		 'member_list', 2,
sub
#line 995 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 173
		 'member', 3,
sub
#line 1004 "parser22.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 174
		 'member', 3,
sub
#line 1011 "parser22.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 175
		 'union_type', 8,
sub
#line 1024 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 176
		 'union_type', 8,
sub
#line 1032 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 177
		 'union_type', 6,
sub
#line 1038 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 178
		 'union_type', 5,
sub
#line 1044 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 179
		 'union_type', 3,
sub
#line 1050 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 180
		 'union_header', 2,
sub
#line 1059 "parser22.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 181
		 'switch_type_spec', 1, undef
	],
	[#Rule 182
		 'switch_type_spec', 1, undef
	],
	[#Rule 183
		 'switch_type_spec', 1, undef
	],
	[#Rule 184
		 'switch_type_spec', 1, undef
	],
	[#Rule 185
		 'switch_type_spec', 1,
sub
#line 1077 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 186
		 'switch_body', 1,
sub
#line 1085 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 187
		 'switch_body', 2,
sub
#line 1089 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 188
		 'case', 3,
sub
#line 1098 "parser22.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 189
		 'case', 3,
sub
#line 1105 "parser22.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 190
		 'case_labels', 1,
sub
#line 1117 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 191
		 'case_labels', 2,
sub
#line 1121 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 192
		 'case_label', 3,
sub
#line 1130 "parser22.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 193
		 'case_label', 3,
sub
#line 1134 "parser22.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 194
		 'case_label', 2,
sub
#line 1140 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 195
		 'case_label', 2,
sub
#line 1145 "parser22.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 196
		 'case_label', 2,
sub
#line 1149 "parser22.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 197
		 'element_spec', 2,
sub
#line 1159 "parser22.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 198
		 'enum_type', 4,
sub
#line 1170 "parser22.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 199
		 'enum_type', 4,
sub
#line 1176 "parser22.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 200
		 'enum_type', 2,
sub
#line 1181 "parser22.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 201
		 'enum_header', 2,
sub
#line 1189 "parser22.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 202
		 'enum_header', 2,
sub
#line 1195 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 203
		 'enumerators', 1,
sub
#line 1203 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 204
		 'enumerators', 3,
sub
#line 1207 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 205
		 'enumerators', 2,
sub
#line 1212 "parser22.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 206
		 'enumerators', 2,
sub
#line 1217 "parser22.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 207
		 'enumerator', 1,
sub
#line 1226 "parser22.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 208
		 'sequence_type', 6,
sub
#line 1236 "parser22.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 209
		 'sequence_type', 6,
sub
#line 1244 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 210
		 'sequence_type', 4,
sub
#line 1249 "parser22.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 211
		 'sequence_type', 4,
sub
#line 1256 "parser22.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 212
		 'sequence_type', 2,
sub
#line 1261 "parser22.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 213
		 'string_type', 4,
sub
#line 1270 "parser22.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 214
		 'string_type', 1,
sub
#line 1277 "parser22.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 215
		 'string_type', 4,
sub
#line 1283 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 216
		 'wide_string_type', 4,
sub
#line 1292 "parser22.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 217
		 'wide_string_type', 1,
sub
#line 1299 "parser22.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 218
		 'wide_string_type', 4,
sub
#line 1305 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 219
		 'array_declarator', 2,
sub
#line 1314 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 220
		 'fixed_array_sizes', 1,
sub
#line 1322 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 221
		 'fixed_array_sizes', 2,
sub
#line 1326 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 222
		 'fixed_array_size', 3,
sub
#line 1335 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 223
		 'fixed_array_size', 3,
sub
#line 1339 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 224
		 'attr_dcl', 4,
sub
#line 1348 "parser22.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 225
		 'attr_dcl', 4,
sub
#line 1356 "parser22.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 226
		 'attr_dcl', 3,
sub
#line 1361 "parser22.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 227
		 'attr_mod', 1, undef
	],
	[#Rule 228
		 'attr_mod', 0, undef
	],
	[#Rule 229
		 'simple_declarators', 1,
sub
#line 1376 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 230
		 'simple_declarators', 3,
sub
#line 1380 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 231
		 'except_dcl', 3,
sub
#line 1389 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 232
		 'except_dcl', 4,
sub
#line 1394 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 233
		 'except_dcl', 4,
sub
#line 1401 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 234
		 'except_dcl', 2,
sub
#line 1407 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 235
		 'exception_header', 2,
sub
#line 1416 "parser22.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 236
		 'exception_header', 2,
sub
#line 1422 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 237
		 'op_dcl', 2,
sub
#line 1431 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 238
		 'op_dcl', 3,
sub
#line 1439 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 239
		 'op_dcl', 4,
sub
#line 1448 "parser22.yp"
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
	[#Rule 240
		 'op_dcl', 3,
sub
#line 1458 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 241
		 'op_dcl', 2,
sub
#line 1467 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 242
		 'op_header', 3,
sub
#line 1477 "parser22.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 243
		 'op_header', 3,
sub
#line 1485 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 244
		 'op_mod', 1, undef
	],
	[#Rule 245
		 'op_mod', 0, undef
	],
	[#Rule 246
		 'op_attribute', 1, undef
	],
	[#Rule 247
		 'op_type_spec', 1, undef
	],
	[#Rule 248
		 'op_type_spec', 1,
sub
#line 1509 "parser22.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 249
		 'parameter_dcls', 3,
sub
#line 1519 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 250
		 'parameter_dcls', 2,
sub
#line 1523 "parser22.yp"
{
			undef;
		}
	],
	[#Rule 251
		 'parameter_dcls', 3,
sub
#line 1527 "parser22.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 252
		 'param_dcls', 1,
sub
#line 1535 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 253
		 'param_dcls', 3,
sub
#line 1539 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 254
		 'param_dcls', 2,
sub
#line 1544 "parser22.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 255
		 'param_dcls', 2,
sub
#line 1549 "parser22.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 256
		 'param_dcl', 3,
sub
#line 1558 "parser22.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 257
		 'param_attribute', 1, undef
	],
	[#Rule 258
		 'param_attribute', 1, undef
	],
	[#Rule 259
		 'param_attribute', 1, undef
	],
	[#Rule 260
		 'raises_expr', 4,
sub
#line 1580 "parser22.yp"
{
			$_[3];
		}
	],
	[#Rule 261
		 'raises_expr', 4,
sub
#line 1584 "parser22.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 262
		 'raises_expr', 2,
sub
#line 1589 "parser22.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 263
		 'exception_names', 1,
sub
#line 1597 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 264
		 'exception_names', 3,
sub
#line 1601 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 265
		 'exception_name', 1,
sub
#line 1609 "parser22.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 266
		 'context_expr', 4,
sub
#line 1617 "parser22.yp"
{
			$_[3];
		}
	],
	[#Rule 267
		 'context_expr', 4,
sub
#line 1621 "parser22.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 268
		 'context_expr', 2,
sub
#line 1626 "parser22.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 269
		 'string_literals', 1,
sub
#line 1634 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 270
		 'string_literals', 3,
sub
#line 1638 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 271
		 'param_type_spec', 1, undef
	],
	[#Rule 272
		 'param_type_spec', 1, undef
	],
	[#Rule 273
		 'param_type_spec', 1, undef
	],
	[#Rule 274
		 'param_type_spec', 1, undef
	],
	[#Rule 275
		 'param_type_spec', 1,
sub
#line 1655 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 276
		 'fixed_pt_type', 6,
sub
#line 1663 "parser22.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 277
		 'fixed_pt_type', 6,
sub
#line 1671 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 278
		 'fixed_pt_type', 4,
sub
#line 1676 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'fixed_pt_type', 2,
sub
#line 1681 "parser22.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 280
		 'fixed_pt_const_type', 1,
sub
#line 1690 "parser22.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 1697 "parser22.yp"


package Parser;

use strict;
use vars qw($IDL_version);
$IDL_version = '2.2';

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
