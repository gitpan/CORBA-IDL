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
		DEFAULT => -110
	},
	{#State 10
		ACTIONS => {
			"{" => 45,
			'error' => 44
		}
	},
	{#State 11
		DEFAULT => -111
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
		DEFAULT => -112
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
		DEFAULT => -113
	},
	{#State 33
		DEFAULT => -142
	},
	{#State 34
		DEFAULT => -115
	},
	{#State 35
		ACTIONS => {
			'CHAR' => -244,
			'OBJECT' => -244,
			'ONEWAY' => 124,
			'FIXED' => -244,
			'NATIVE' => 2,
			'VOID' => -244,
			'STRUCT' => 6,
			'DOUBLE' => -244,
			'LONG' => -244,
			'STRING' => -244,
			"::" => -244,
			'WSTRING' => -244,
			'UNSIGNED' => -244,
			'SHORT' => -244,
			'TYPEDEF' => 12,
			'BOOLEAN' => -244,
			'IDENTIFIER' => -244,
			'UNION' => 16,
			'READONLY' => 135,
			'WCHAR' => -244,
			'ATTRIBUTE' => -227,
			'error' => 129,
			'CONST' => 22,
			"}" => 130,
			'EXCEPTION' => 23,
			'OCTET' => -244,
			'FLOAT' => -244,
			'ENUM' => 28,
			'ANY' => -244
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
		DEFAULT => -169
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
		DEFAULT => -233
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
		DEFAULT => -148
	},
	{#State 47
		DEFAULT => -123
	},
	{#State 48
		ACTIONS => {
			"<" => 148,
			'error' => 147
		}
	},
	{#State 49
		DEFAULT => -147
	},
	{#State 50
		ACTIONS => {
			"<" => 150,
			'error' => 149
		}
	},
	{#State 51
		DEFAULT => -125
	},
	{#State 52
		DEFAULT => -130
	},
	{#State 53
		DEFAULT => -128
	},
	{#State 54
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -122
	},
	{#State 55
		DEFAULT => -126
	},
	{#State 56
		DEFAULT => -150
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
		DEFAULT => -109
	},
	{#State 59
		ACTIONS => {
			'SHORT' => 159,
			'LONG' => 160
		}
	},
	{#State 60
		DEFAULT => -132
	},
	{#State 61
		DEFAULT => -152
	},
	{#State 62
		DEFAULT => -162
	},
	{#State 63
		DEFAULT => -157
	},
	{#State 64
		DEFAULT => -129
	},
	{#State 65
		DEFAULT => -120
	},
	{#State 66
		DEFAULT => -137
	},
	{#State 67
		DEFAULT => -114
	},
	{#State 68
		DEFAULT => -164
	},
	{#State 69
		DEFAULT => -155
	},
	{#State 70
		DEFAULT => -144
	},
	{#State 71
		DEFAULT => -151
	},
	{#State 72
		DEFAULT => -165
	},
	{#State 73
		DEFAULT => -161
	},
	{#State 74
		DEFAULT => -166
	},
	{#State 75
		DEFAULT => -133
	},
	{#State 76
		DEFAULT => -124
	},
	{#State 77
		DEFAULT => -127
	},
	{#State 78
		DEFAULT => -145
	},
	{#State 79
		ACTIONS => {
			'LONG' => 162,
			'DOUBLE' => 161
		},
		DEFAULT => -153
	},
	{#State 80
		ACTIONS => {
			"<" => 163
		},
		DEFAULT => -213
	},
	{#State 81
		ACTIONS => {
			'error' => 164,
			'IDENTIFIER' => 165
		}
	},
	{#State 82
		DEFAULT => -149
	},
	{#State 83
		ACTIONS => {
			"<" => 166
		},
		DEFAULT => -216
	},
	{#State 84
		DEFAULT => -135
	},
	{#State 85
		DEFAULT => -163
	},
	{#State 86
		DEFAULT => -136
	},
	{#State 87
		DEFAULT => -49
	},
	{#State 88
		DEFAULT => -131
	},
	{#State 89
		DEFAULT => -156
	},
	{#State 90
		DEFAULT => -121
	},
	{#State 91
		DEFAULT => -119
	},
	{#State 92
		DEFAULT => -118
	},
	{#State 93
		DEFAULT => -134
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
		DEFAULT => -179
	},
	{#State 98
		DEFAULT => -199
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
		DEFAULT => -63
	},
	{#State 103
		DEFAULT => -279
	},
	{#State 104
		DEFAULT => -60
	},
	{#State 105
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -67
	},
	{#State 106
		DEFAULT => -61
	},
	{#State 107
		DEFAULT => -64
	},
	{#State 108
		DEFAULT => -58
	},
	{#State 109
		DEFAULT => -65
	},
	{#State 110
		DEFAULT => -62
	},
	{#State 111
		DEFAULT => -59
	},
	{#State 112
		DEFAULT => -66
	},
	{#State 113
		ACTIONS => {
			'error' => 173,
			'IDENTIFIER' => 174
		}
	},
	{#State 114
		DEFAULT => -235
	},
	{#State 115
		DEFAULT => -234
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
		DEFAULT => -201
	},
	{#State 121
		DEFAULT => -200
	},
	{#State 122
		ACTIONS => {
			"{" => -30
		},
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
		DEFAULT => -245
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
		DEFAULT => -243
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
		DEFAULT => -31
	},
	{#State 133
		ACTIONS => {
			'ONEWAY' => 124,
			'NATIVE' => 2,
			'STRUCT' => 6,
			'TYPEDEF' => 12,
			'UNION' => 16,
			'READONLY' => 135,
			'ATTRIBUTE' => -227,
			'CONST' => 22,
			"}" => -32,
			'EXCEPTION' => 23,
			'ENUM' => 28
		},
		DEFAULT => -244,
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
		DEFAULT => -226
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
		DEFAULT => -230
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
		DEFAULT => -170,
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
		DEFAULT => -278
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
		DEFAULT => -211
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
		DEFAULT => -116
	},
	{#State 153
		ACTIONS => {
			"," => 244
		},
		DEFAULT => -138
	},
	{#State 154
		DEFAULT => -117
	},
	{#State 155
		DEFAULT => -141
	},
	{#State 156
		DEFAULT => -140
	},
	{#State 157
		DEFAULT => -143
	},
	{#State 158
		ACTIONS => {
			"[" => 247
		},
		DEFAULT => -142,
		GOTOS => {
			'fixed_array_sizes' => 245,
			'fixed_array_size' => 246
		}
	},
	{#State 159
		DEFAULT => -158
	},
	{#State 160
		ACTIONS => {
			'LONG' => 248
		},
		DEFAULT => -159
	},
	{#State 161
		DEFAULT => -146
	},
	{#State 162
		DEFAULT => -154
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
		DEFAULT => -51
	},
	{#State 165
		DEFAULT => -50
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
		DEFAULT => -202
	},
	{#State 171
		DEFAULT => -206
	},
	{#State 172
		ACTIONS => {
			"}" => 258
		}
	},
	{#State 173
		DEFAULT => -57
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
		DEFAULT => -178
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
		DEFAULT => -274
	},
	{#State 180
		DEFAULT => -271
	},
	{#State 181
		DEFAULT => -270
	},
	{#State 182
		DEFAULT => -246
	},
	{#State 183
		DEFAULT => -272
	},
	{#State 184
		DEFAULT => -247
	},
	{#State 185
		ACTIONS => {
			'error' => 273,
			'IDENTIFIER' => 274
		}
	},
	{#State 186
		DEFAULT => -273
	},
	{#State 187
		DEFAULT => -36
	},
	{#State 188
		DEFAULT => -41
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
		DEFAULT => -35
	},
	{#State 192
		DEFAULT => -40
	},
	{#State 193
		DEFAULT => -33
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
		DEFAULT => -240
	},
	{#State 196
		ACTIONS => {
			'RAISES' => 288,
			'CONTEXT' => 285
		},
		DEFAULT => -236,
		GOTOS => {
			'context_expr' => 287,
			'raises_expr' => 286
		}
	},
	{#State 197
		DEFAULT => -38
	},
	{#State 198
		DEFAULT => -43
	},
	{#State 199
		DEFAULT => -37
	},
	{#State 200
		DEFAULT => -42
	},
	{#State 201
		DEFAULT => -34
	},
	{#State 202
		DEFAULT => -39
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
		DEFAULT => -232
	},
	{#State 208
		DEFAULT => -231
	},
	{#State 209
		DEFAULT => -171
	},
	{#State 210
		DEFAULT => -97
	},
	{#State 211
		DEFAULT => -98
	},
	{#State 212
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -90
	},
	{#State 213
		ACTIONS => {
			"," => 291
		}
	},
	{#State 214
		DEFAULT => -96
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
		DEFAULT => -101
	},
	{#State 217
		DEFAULT => -108
	},
	{#State 218
		ACTIONS => {
			"|" => 294
		},
		DEFAULT => -68
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
		DEFAULT => -69
	},
	{#State 221
		ACTIONS => {
			"<<" => 297,
			">>" => 298
		},
		DEFAULT => -73
	},
	{#State 222
		DEFAULT => -107
	},
	{#State 223
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 223
		},
		DEFAULT => -104,
		GOTOS => {
			'wide_string_literal' => 299
		}
	},
	{#State 224
		DEFAULT => -91
	},
	{#State 225
		DEFAULT => -106
	},
	{#State 226
		ACTIONS => {
			"+" => 300,
			"-" => 301
		},
		DEFAULT => -75
	},
	{#State 227
		DEFAULT => -95
	},
	{#State 228
		DEFAULT => -100
	},
	{#State 229
		DEFAULT => -86
	},
	{#State 230
		ACTIONS => {
			"&" => 302
		},
		DEFAULT => -71
	},
	{#State 231
		DEFAULT => -94
	},
	{#State 232
		ACTIONS => {
			"%" => 304,
			"*" => 303,
			"/" => 305
		},
		DEFAULT => -78
	},
	{#State 233
		ACTIONS => {
			'STRING_LITERAL' => 233
		},
		DEFAULT => -102,
		GOTOS => {
			'string_literal' => 306
		}
	},
	{#State 234
		DEFAULT => -99
	},
	{#State 235
		DEFAULT => -88
	},
	{#State 236
		DEFAULT => -81
	},
	{#State 237
		DEFAULT => -87
	},
	{#State 238
		DEFAULT => -89
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
		DEFAULT => -53
	},
	{#State 243
		DEFAULT => -52
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
		DEFAULT => -218
	},
	{#State 246
		ACTIONS => {
			"[" => 247
		},
		DEFAULT => -219,
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
		DEFAULT => -160
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
		DEFAULT => -168
	},
	{#State 254
		DEFAULT => -167
	},
	{#State 255
		DEFAULT => -198
	},
	{#State 256
		DEFAULT => -205
	},
	{#State 257
		ACTIONS => {
			'IDENTIFIER' => 171
		},
		DEFAULT => -204,
		GOTOS => {
			'enumerators' => 319,
			'enumerator' => 170
		}
	},
	{#State 258
		DEFAULT => -197
	},
	{#State 259
		DEFAULT => -56
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
		DEFAULT => -181
	},
	{#State 262
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -184
	},
	{#State 263
		DEFAULT => -183
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
		DEFAULT => -182
	},
	{#State 267
		DEFAULT => -180
	},
	{#State 268
		ACTIONS => {
			'LONG' => 162
		},
		DEFAULT => -153
	},
	{#State 269
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -48
	},
	{#State 270
		DEFAULT => -45
	},
	{#State 271
		ACTIONS => {
			"," => 324
		},
		DEFAULT => -46
	},
	{#State 272
		DEFAULT => -44
	},
	{#State 273
		DEFAULT => -242
	},
	{#State 274
		DEFAULT => -241
	},
	{#State 275
		DEFAULT => -225
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
		DEFAULT => -256
	},
	{#State 278
		ACTIONS => {
			")" => 328
		}
	},
	{#State 279
		DEFAULT => -258
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
		DEFAULT => -249
	},
	{#State 283
		DEFAULT => -257
	},
	{#State 284
		ACTIONS => {
			";" => 331,
			"," => 332
		},
		DEFAULT => -251
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
		DEFAULT => -237,
		GOTOS => {
			'context_expr' => 335
		}
	},
	{#State 287
		DEFAULT => -239
	},
	{#State 288
		ACTIONS => {
			'error' => 337,
			"(" => 336
		}
	},
	{#State 289
		DEFAULT => -172
	},
	{#State 290
		DEFAULT => -173
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
		DEFAULT => -277
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
		DEFAULT => -105
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
		DEFAULT => -103
	},
	{#State 307
		DEFAULT => -85
	},
	{#State 308
		DEFAULT => -210
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
		DEFAULT => -209
	},
	{#State 311
		DEFAULT => -139
	},
	{#State 312
		DEFAULT => -220
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
		DEFAULT => -212
	},
	{#State 316
		DEFAULT => -214
	},
	{#State 317
		DEFAULT => -215
	},
	{#State 318
		DEFAULT => -217
	},
	{#State 319
		DEFAULT => -203
	},
	{#State 320
		DEFAULT => -54
	},
	{#State 321
		DEFAULT => -55
	},
	{#State 322
		DEFAULT => -177
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
		DEFAULT => -224
	},
	{#State 326
		ACTIONS => {
			"," => 359
		},
		DEFAULT => -228
	},
	{#State 327
		DEFAULT => -223
	},
	{#State 328
		DEFAULT => -250
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
		DEFAULT => -248
	},
	{#State 331
		DEFAULT => -254
	},
	{#State 332
		ACTIONS => {
			'OUT' => 283,
			'INOUT' => 279,
			'IN' => 277
		},
		DEFAULT => -253,
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
		DEFAULT => -267
	},
	{#State 335
		DEFAULT => -238
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
		DEFAULT => -261
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
		DEFAULT => -92
	},
	{#State 341
		DEFAULT => -93
	},
	{#State 342
		ACTIONS => {
			"^" => 296
		},
		DEFAULT => -70
	},
	{#State 343
		ACTIONS => {
			"&" => 302
		},
		DEFAULT => -72
	},
	{#State 344
		ACTIONS => {
			"+" => 300,
			"-" => 301
		},
		DEFAULT => -77
	},
	{#State 345
		ACTIONS => {
			"+" => 300,
			"-" => 301
		},
		DEFAULT => -76
	},
	{#State 346
		ACTIONS => {
			"%" => 304,
			"*" => 303,
			"/" => 305
		},
		DEFAULT => -79
	},
	{#State 347
		ACTIONS => {
			"%" => 304,
			"*" => 303,
			"/" => 305
		},
		DEFAULT => -80
	},
	{#State 348
		ACTIONS => {
			"<<" => 297,
			">>" => 298
		},
		DEFAULT => -74
	},
	{#State 349
		DEFAULT => -82
	},
	{#State 350
		DEFAULT => -84
	},
	{#State 351
		DEFAULT => -83
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
		DEFAULT => -221
	},
	{#State 355
		DEFAULT => -222
	},
	{#State 356
		DEFAULT => -176
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
		DEFAULT => -47
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
		DEFAULT => -255
	},
	{#State 361
		DEFAULT => -252
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
		DEFAULT => -268
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
		DEFAULT => -264
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
		DEFAULT => -262
	},
	{#State 369
		DEFAULT => -275
	},
	{#State 370
		DEFAULT => -276
	},
	{#State 371
		DEFAULT => -207
	},
	{#State 372
		DEFAULT => -208
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
		DEFAULT => -185,
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
		DEFAULT => -189,
		GOTOS => {
			'case_labels' => 396,
			'case_label' => 379
		}
	},
	{#State 380
		DEFAULT => -229
	},
	{#State 381
		DEFAULT => -266
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
		DEFAULT => -265
	},
	{#State 384
		DEFAULT => -260
	},
	{#State 385
		DEFAULT => -259
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
		DEFAULT => -193
	},
	{#State 389
		DEFAULT => -186
	},
	{#State 390
		DEFAULT => -195
	},
	{#State 391
		DEFAULT => -194
	},
	{#State 392
		DEFAULT => -175
	},
	{#State 393
		DEFAULT => -174
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
		DEFAULT => -190
	},
	{#State 397
		DEFAULT => -269
	},
	{#State 398
		DEFAULT => -263
	},
	{#State 399
		DEFAULT => -192
	},
	{#State 400
		DEFAULT => -191
	},
	{#State 401
		DEFAULT => -196
	},
	{#State 402
		DEFAULT => -187
	},
	{#State 403
		DEFAULT => -188
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
		 'module', 4,
sub
#line 134 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 17
		 'module', 4,
sub
#line 141 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 18
		 'module', 2,
sub
#line 147 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 156 "parser22.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 162 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
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
#line 179 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 187 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 25
		 'interface_dcl', 4,
sub
#line 195 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 26
		 'forward_dcl', 2,
sub
#line 206 "parser22.yp"
{
			new ForwardRegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 27
		 'forward_dcl', 2,
sub
#line 212 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'interface_header', 2,
sub
#line 221 "parser22.yp"
{
			new RegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 29
		 'interface_header', 3,
sub
#line 227 "parser22.yp"
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
	[#Rule 30
		 'interface_header', 2,
sub
#line 237 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 31
		 'interface_body', 1, undef
	],
	[#Rule 32
		 'exports', 1,
sub
#line 251 "parser22.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 33
		 'exports', 2,
sub
#line 255 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
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
		 'export', 2, undef
	],
	[#Rule 39
		 'export', 2,
sub
#line 274 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 40
		 'export', 2,
sub
#line 280 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 41
		 'export', 2,
sub
#line 286 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 42
		 'export', 2,
sub
#line 292 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 43
		 'export', 2,
sub
#line 298 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 44
		 'interface_inheritance_spec', 2,
sub
#line 308 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 45
		 'interface_inheritance_spec', 2,
sub
#line 312 "parser22.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 46
		 'interface_names', 1,
sub
#line 320 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 47
		 'interface_names', 3,
sub
#line 324 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 48
		 'interface_name', 1,
sub
#line 332 "parser22.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 49
		 'scoped_name', 1, undef
	],
	[#Rule 50
		 'scoped_name', 2,
sub
#line 342 "parser22.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 51
		 'scoped_name', 2,
sub
#line 346 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 52
		 'scoped_name', 3,
sub
#line 352 "parser22.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 53
		 'scoped_name', 3,
sub
#line 356 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 54
		 'const_dcl', 5,
sub
#line 366 "parser22.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 55
		 'const_dcl', 5,
sub
#line 374 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 56
		 'const_dcl', 4,
sub
#line 379 "parser22.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 57
		 'const_dcl', 3,
sub
#line 384 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 58
		 'const_dcl', 2,
sub
#line 389 "parser22.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
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
		 'const_type', 1, undef
	],
	[#Rule 67
		 'const_type', 1,
sub
#line 414 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 68
		 'const_exp', 1, undef
	],
	[#Rule 69
		 'or_expr', 1, undef
	],
	[#Rule 70
		 'or_expr', 3,
sub
#line 430 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 71
		 'xor_expr', 1, undef
	],
	[#Rule 72
		 'xor_expr', 3,
sub
#line 440 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 73
		 'and_expr', 1, undef
	],
	[#Rule 74
		 'and_expr', 3,
sub
#line 450 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 75
		 'shift_expr', 1, undef
	],
	[#Rule 76
		 'shift_expr', 3,
sub
#line 460 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 77
		 'shift_expr', 3,
sub
#line 464 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 78
		 'add_expr', 1, undef
	],
	[#Rule 79
		 'add_expr', 3,
sub
#line 474 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 80
		 'add_expr', 3,
sub
#line 478 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 81
		 'mult_expr', 1, undef
	],
	[#Rule 82
		 'mult_expr', 3,
sub
#line 488 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 83
		 'mult_expr', 3,
sub
#line 492 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 84
		 'mult_expr', 3,
sub
#line 496 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 85
		 'unary_expr', 2,
sub
#line 504 "parser22.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 86
		 'unary_expr', 1, undef
	],
	[#Rule 87
		 'unary_operator', 1, undef
	],
	[#Rule 88
		 'unary_operator', 1, undef
	],
	[#Rule 89
		 'unary_operator', 1, undef
	],
	[#Rule 90
		 'primary_expr', 1,
sub
#line 524 "parser22.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 91
		 'primary_expr', 1,
sub
#line 530 "parser22.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 92
		 'primary_expr', 3,
sub
#line 534 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 93
		 'primary_expr', 3,
sub
#line 538 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 94
		 'literal', 1,
sub
#line 547 "parser22.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 95
		 'literal', 1,
sub
#line 554 "parser22.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 96
		 'literal', 1,
sub
#line 560 "parser22.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 97
		 'literal', 1,
sub
#line 566 "parser22.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 98
		 'literal', 1,
sub
#line 572 "parser22.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 99
		 'literal', 1,
sub
#line 578 "parser22.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 100
		 'literal', 1,
sub
#line 585 "parser22.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 101
		 'literal', 1, undef
	],
	[#Rule 102
		 'string_literal', 1, undef
	],
	[#Rule 103
		 'string_literal', 2,
sub
#line 599 "parser22.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 104
		 'wide_string_literal', 1, undef
	],
	[#Rule 105
		 'wide_string_literal', 2,
sub
#line 608 "parser22.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 106
		 'boolean_literal', 1,
sub
#line 616 "parser22.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 107
		 'boolean_literal', 1,
sub
#line 622 "parser22.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 108
		 'positive_int_const', 1,
sub
#line 632 "parser22.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 109
		 'type_dcl', 2,
sub
#line 642 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 110
		 'type_dcl', 1, undef
	],
	[#Rule 111
		 'type_dcl', 1, undef
	],
	[#Rule 112
		 'type_dcl', 1, undef
	],
	[#Rule 113
		 'type_dcl', 2,
sub
#line 652 "parser22.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 114
		 'type_dcl', 2,
sub
#line 659 "parser22.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 115
		 'type_dcl', 2,
sub
#line 664 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 116
		 'type_declarator', 2,
sub
#line 673 "parser22.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 117
		 'type_declarator', 2,
sub
#line 680 "parser22.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 118
		 'type_spec', 1, undef
	],
	[#Rule 119
		 'type_spec', 1, undef
	],
	[#Rule 120
		 'simple_type_spec', 1, undef
	],
	[#Rule 121
		 'simple_type_spec', 1, undef
	],
	[#Rule 122
		 'simple_type_spec', 1,
sub
#line 701 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
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
		 'base_type_spec', 1, undef
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
		 'template_type_spec', 1, undef
	],
	[#Rule 135
		 'constr_type_spec', 1, undef
	],
	[#Rule 136
		 'constr_type_spec', 1, undef
	],
	[#Rule 137
		 'constr_type_spec', 1, undef
	],
	[#Rule 138
		 'declarators', 1,
sub
#line 751 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 139
		 'declarators', 3,
sub
#line 755 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 140
		 'declarator', 1,
sub
#line 764 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 141
		 'declarator', 1, undef
	],
	[#Rule 142
		 'simple_declarator', 1, undef
	],
	[#Rule 143
		 'complex_declarator', 1, undef
	],
	[#Rule 144
		 'floating_pt_type', 1,
sub
#line 786 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 145
		 'floating_pt_type', 1,
sub
#line 792 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 146
		 'floating_pt_type', 2,
sub
#line 798 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 147
		 'integer_type', 1, undef
	],
	[#Rule 148
		 'integer_type', 1, undef
	],
	[#Rule 149
		 'signed_int', 1, undef
	],
	[#Rule 150
		 'signed_int', 1, undef
	],
	[#Rule 151
		 'signed_int', 1, undef
	],
	[#Rule 152
		 'signed_short_int', 1,
sub
#line 826 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 153
		 'signed_long_int', 1,
sub
#line 836 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 154
		 'signed_longlong_int', 2,
sub
#line 846 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 155
		 'unsigned_int', 1, undef
	],
	[#Rule 156
		 'unsigned_int', 1, undef
	],
	[#Rule 157
		 'unsigned_int', 1, undef
	],
	[#Rule 158
		 'unsigned_short_int', 2,
sub
#line 866 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 159
		 'unsigned_long_int', 2,
sub
#line 876 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 160
		 'unsigned_longlong_int', 3,
sub
#line 886 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 161
		 'char_type', 1,
sub
#line 896 "parser22.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'wide_char_type', 1,
sub
#line 906 "parser22.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'boolean_type', 1,
sub
#line 916 "parser22.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 164
		 'octet_type', 1,
sub
#line 926 "parser22.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 165
		 'any_type', 1,
sub
#line 936 "parser22.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 166
		 'object_type', 1,
sub
#line 946 "parser22.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 167
		 'struct_type', 4,
sub
#line 956 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 168
		 'struct_type', 4,
sub
#line 963 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 169
		 'struct_header', 2,
sub
#line 972 "parser22.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 170
		 'member_list', 1,
sub
#line 982 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 171
		 'member_list', 2,
sub
#line 986 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 172
		 'member', 3,
sub
#line 995 "parser22.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 173
		 'member', 3,
sub
#line 1002 "parser22.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 174
		 'union_type', 8,
sub
#line 1015 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 175
		 'union_type', 8,
sub
#line 1023 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 176
		 'union_type', 6,
sub
#line 1029 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 177
		 'union_type', 5,
sub
#line 1035 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 178
		 'union_type', 3,
sub
#line 1041 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 179
		 'union_header', 2,
sub
#line 1050 "parser22.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
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
		 'switch_type_spec', 1, undef
	],
	[#Rule 184
		 'switch_type_spec', 1,
sub
#line 1068 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 185
		 'switch_body', 1,
sub
#line 1076 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 186
		 'switch_body', 2,
sub
#line 1080 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 187
		 'case', 3,
sub
#line 1089 "parser22.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 188
		 'case', 3,
sub
#line 1096 "parser22.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 189
		 'case_labels', 1,
sub
#line 1108 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 190
		 'case_labels', 2,
sub
#line 1112 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 191
		 'case_label', 3,
sub
#line 1121 "parser22.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 192
		 'case_label', 3,
sub
#line 1125 "parser22.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 193
		 'case_label', 2,
sub
#line 1131 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 194
		 'case_label', 2,
sub
#line 1136 "parser22.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 195
		 'case_label', 2,
sub
#line 1140 "parser22.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 196
		 'element_spec', 2,
sub
#line 1150 "parser22.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 197
		 'enum_type', 4,
sub
#line 1161 "parser22.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 198
		 'enum_type', 4,
sub
#line 1167 "parser22.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 199
		 'enum_type', 2,
sub
#line 1172 "parser22.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 200
		 'enum_header', 2,
sub
#line 1180 "parser22.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 201
		 'enum_header', 2,
sub
#line 1186 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 202
		 'enumerators', 1,
sub
#line 1194 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 203
		 'enumerators', 3,
sub
#line 1198 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 204
		 'enumerators', 2,
sub
#line 1203 "parser22.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 205
		 'enumerators', 2,
sub
#line 1208 "parser22.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 206
		 'enumerator', 1,
sub
#line 1217 "parser22.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 207
		 'sequence_type', 6,
sub
#line 1227 "parser22.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 208
		 'sequence_type', 6,
sub
#line 1235 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 209
		 'sequence_type', 4,
sub
#line 1240 "parser22.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 210
		 'sequence_type', 4,
sub
#line 1247 "parser22.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 211
		 'sequence_type', 2,
sub
#line 1252 "parser22.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 212
		 'string_type', 4,
sub
#line 1261 "parser22.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 213
		 'string_type', 1,
sub
#line 1268 "parser22.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 214
		 'string_type', 4,
sub
#line 1274 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 215
		 'wide_string_type', 4,
sub
#line 1283 "parser22.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 216
		 'wide_string_type', 1,
sub
#line 1290 "parser22.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 217
		 'wide_string_type', 4,
sub
#line 1296 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 218
		 'array_declarator', 2,
sub
#line 1305 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 219
		 'fixed_array_sizes', 1,
sub
#line 1313 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 220
		 'fixed_array_sizes', 2,
sub
#line 1317 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 221
		 'fixed_array_size', 3,
sub
#line 1326 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 222
		 'fixed_array_size', 3,
sub
#line 1330 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 223
		 'attr_dcl', 4,
sub
#line 1339 "parser22.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 224
		 'attr_dcl', 4,
sub
#line 1347 "parser22.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 225
		 'attr_dcl', 3,
sub
#line 1352 "parser22.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 226
		 'attr_mod', 1, undef
	],
	[#Rule 227
		 'attr_mod', 0, undef
	],
	[#Rule 228
		 'simple_declarators', 1,
sub
#line 1367 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 229
		 'simple_declarators', 3,
sub
#line 1371 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 230
		 'except_dcl', 3,
sub
#line 1380 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 231
		 'except_dcl', 4,
sub
#line 1385 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 232
		 'except_dcl', 4,
sub
#line 1392 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 233
		 'except_dcl', 2,
sub
#line 1398 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 234
		 'exception_header', 2,
sub
#line 1407 "parser22.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 235
		 'exception_header', 2,
sub
#line 1413 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 236
		 'op_dcl', 2,
sub
#line 1422 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 237
		 'op_dcl', 3,
sub
#line 1430 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 238
		 'op_dcl', 4,
sub
#line 1439 "parser22.yp"
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
	[#Rule 239
		 'op_dcl', 3,
sub
#line 1449 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 240
		 'op_dcl', 2,
sub
#line 1458 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 241
		 'op_header', 3,
sub
#line 1468 "parser22.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 242
		 'op_header', 3,
sub
#line 1476 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'op_mod', 1, undef
	],
	[#Rule 244
		 'op_mod', 0, undef
	],
	[#Rule 245
		 'op_attribute', 1, undef
	],
	[#Rule 246
		 'op_type_spec', 1, undef
	],
	[#Rule 247
		 'op_type_spec', 1,
sub
#line 1500 "parser22.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 248
		 'parameter_dcls', 3,
sub
#line 1510 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 249
		 'parameter_dcls', 2,
sub
#line 1514 "parser22.yp"
{
			undef;
		}
	],
	[#Rule 250
		 'parameter_dcls', 3,
sub
#line 1518 "parser22.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 251
		 'param_dcls', 1,
sub
#line 1526 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 252
		 'param_dcls', 3,
sub
#line 1530 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 253
		 'param_dcls', 2,
sub
#line 1535 "parser22.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 254
		 'param_dcls', 2,
sub
#line 1540 "parser22.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 255
		 'param_dcl', 3,
sub
#line 1549 "parser22.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 256
		 'param_attribute', 1, undef
	],
	[#Rule 257
		 'param_attribute', 1, undef
	],
	[#Rule 258
		 'param_attribute', 1, undef
	],
	[#Rule 259
		 'raises_expr', 4,
sub
#line 1571 "parser22.yp"
{
			$_[3];
		}
	],
	[#Rule 260
		 'raises_expr', 4,
sub
#line 1575 "parser22.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 261
		 'raises_expr', 2,
sub
#line 1580 "parser22.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 262
		 'exception_names', 1,
sub
#line 1588 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 263
		 'exception_names', 3,
sub
#line 1592 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 264
		 'exception_name', 1,
sub
#line 1600 "parser22.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 265
		 'context_expr', 4,
sub
#line 1608 "parser22.yp"
{
			$_[3];
		}
	],
	[#Rule 266
		 'context_expr', 4,
sub
#line 1612 "parser22.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 267
		 'context_expr', 2,
sub
#line 1617 "parser22.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 268
		 'string_literals', 1,
sub
#line 1625 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 269
		 'string_literals', 3,
sub
#line 1629 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
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
		 'param_type_spec', 1, undef
	],
	[#Rule 274
		 'param_type_spec', 1,
sub
#line 1646 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 275
		 'fixed_pt_type', 6,
sub
#line 1654 "parser22.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 276
		 'fixed_pt_type', 6,
sub
#line 1662 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 277
		 'fixed_pt_type', 4,
sub
#line 1667 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 278
		 'fixed_pt_type', 2,
sub
#line 1672 "parser22.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'fixed_pt_const_type', 1,
sub
#line 1681 "parser22.yp"
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

#line 1688 "parser22.yp"


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
