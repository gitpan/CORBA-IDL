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
			'TYPEDEF' => 11,
			'MODULE' => 14,
			'IDENTIFIER' => 13,
			'UNION' => 16,
			'STRUCT' => 5,
			'error' => 19,
			'CONST' => 22,
			'EXCEPTION' => 23,
			'ENUM' => 28,
			'INTERFACE' => 29
		},
		GOTOS => {
			'const_dcl' => 1,
			'except_dcl' => 3,
			'interface_header' => 2,
			'specification' => 4,
			'module_header' => 6,
			'interface' => 7,
			'struct_type' => 8,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
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
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 30
		}
	},
	{#State 2
		ACTIONS => {
			"{" => 33
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 34
		}
	},
	{#State 4
		ACTIONS => {
			'' => 35
		}
	},
	{#State 5
		ACTIONS => {
			'error' => 37,
			'IDENTIFIER' => 36
		}
	},
	{#State 6
		ACTIONS => {
			"{" => 39,
			'error' => 38
		}
	},
	{#State 7
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 40
		}
	},
	{#State 8
		DEFAULT => -104
	},
	{#State 9
		ACTIONS => {
			"{" => 42,
			'error' => 41
		}
	},
	{#State 10
		DEFAULT => -105
	},
	{#State 11
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'VOID' => 72,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 76,
			'LONG' => 77,
			'STRING' => 78,
			"::" => 79,
			'WSTRING' => 81,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'UNION' => 16,
			'WCHAR' => 59,
			'error' => 64,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'type_spec' => 54,
			'signed_long_int' => 53,
			'type_declarator' => 55,
			'string_type' => 57,
			'struct_header' => 12,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'enum_type' => 63,
			'enum_header' => 20,
			'union_header' => 24,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68,
			'wide_string_type' => 73,
			'integer_type' => 74,
			'boolean_type' => 75,
			'signed_short_int' => 80,
			'struct_type' => 82,
			'union_type' => 84,
			'sequence_type' => 86,
			'unsigned_long_int' => 87,
			'template_type_spec' => 88,
			'constr_type_spec' => 89,
			'simple_type_spec' => 90,
			'fixed_pt_type' => 91
		}
	},
	{#State 12
		ACTIONS => {
			"{" => 92
		}
	},
	{#State 13
		ACTIONS => {
			'error' => 93
		}
	},
	{#State 14
		ACTIONS => {
			'error' => 94,
			'IDENTIFIER' => 95
		}
	},
	{#State 15
		DEFAULT => -20
	},
	{#State 16
		ACTIONS => {
			'error' => 96,
			'IDENTIFIER' => 97
		}
	},
	{#State 17
		DEFAULT => -106
	},
	{#State 18
		DEFAULT => -21
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
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 100
		}
	},
	{#State 22
		ACTIONS => {
			'CHAR' => 70,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'FIXED' => 102,
			'WCHAR' => 59,
			'DOUBLE' => 76,
			'error' => 107,
			'LONG' => 77,
			'STRING' => 78,
			"::" => 79,
			'FLOAT' => 67,
			'WSTRING' => 81,
			'UNSIGNED' => 56
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 101,
			'signed_int' => 46,
			'wide_string_type' => 108,
			'integer_type' => 110,
			'boolean_type' => 109,
			'char_type' => 103,
			'scoped_name' => 104,
			'fixed_pt_const_type' => 111,
			'wide_char_type' => 105,
			'signed_long_int' => 53,
			'signed_short_int' => 80,
			'const_type' => 112,
			'string_type' => 106,
			'unsigned_longlong_int' => 60,
			'unsigned_long_int' => 87,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68
		}
	},
	{#State 23
		ACTIONS => {
			'error' => 113,
			'IDENTIFIER' => 114
		}
	},
	{#State 24
		ACTIONS => {
			'SWITCH' => 115
		}
	},
	{#State 25
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 116
		}
	},
	{#State 26
		DEFAULT => -1
	},
	{#State 27
		ACTIONS => {
			'TYPEDEF' => 11,
			'IDENTIFIER' => 13,
			'MODULE' => 14,
			'UNION' => 16,
			'STRUCT' => 5,
			'CONST' => 22,
			'EXCEPTION' => 23,
			'ENUM' => 28,
			'INTERFACE' => 29
		},
		DEFAULT => -4,
		GOTOS => {
			'const_dcl' => 1,
			'interface_header' => 2,
			'except_dcl' => 3,
			'module_header' => 6,
			'interface' => 7,
			'struct_type' => 8,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'interface_dcl' => 15,
			'enum_type' => 17,
			'forward_dcl' => 18,
			'enum_header' => 20,
			'module' => 21,
			'union_header' => 24,
			'definitions' => 117,
			'type_dcl' => 25,
			'definition' => 27
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 118,
			'IDENTIFIER' => 119
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 120,
			'IDENTIFIER' => 121
		}
	},
	{#State 30
		DEFAULT => -7
	},
	{#State 31
		DEFAULT => -12
	},
	{#State 32
		DEFAULT => -13
	},
	{#State 33
		ACTIONS => {
			'CHAR' => -234,
			'OBJECT' => -234,
			'ONEWAY' => 122,
			'FIXED' => -234,
			'VOID' => -234,
			'SEQUENCE' => -234,
			'STRUCT' => 5,
			'DOUBLE' => -234,
			'LONG' => -234,
			'STRING' => -234,
			"::" => -234,
			'WSTRING' => -234,
			'UNSIGNED' => -234,
			'SHORT' => -234,
			'TYPEDEF' => 11,
			'BOOLEAN' => -234,
			'IDENTIFIER' => -234,
			'UNION' => 16,
			'READONLY' => 133,
			'WCHAR' => -234,
			'ATTRIBUTE' => -220,
			'error' => 127,
			'CONST' => 22,
			"}" => 128,
			'EXCEPTION' => 23,
			'OCTET' => -234,
			'FLOAT' => -234,
			'ENUM' => 28,
			'ANY' => -234
		},
		GOTOS => {
			'const_dcl' => 129,
			'op_mod' => 123,
			'except_dcl' => 124,
			'op_attribute' => 125,
			'attr_mod' => 126,
			'exports' => 130,
			'export' => 131,
			'struct_type' => 8,
			'op_header' => 132,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 17,
			'op_dcl' => 134,
			'enum_header' => 20,
			'attr_dcl' => 135,
			'type_dcl' => 136,
			'union_header' => 24,
			'interface_body' => 137
		}
	},
	{#State 34
		DEFAULT => -8
	},
	{#State 35
		DEFAULT => 0
	},
	{#State 36
		DEFAULT => -163
	},
	{#State 37
		DEFAULT => -164
	},
	{#State 38
		ACTIONS => {
			"}" => 138
		}
	},
	{#State 39
		ACTIONS => {
			'TYPEDEF' => 11,
			'IDENTIFIER' => 13,
			'MODULE' => 14,
			'UNION' => 16,
			'STRUCT' => 5,
			'error' => 139,
			'CONST' => 22,
			'EXCEPTION' => 23,
			"}" => 140,
			'ENUM' => 28,
			'INTERFACE' => 29
		},
		GOTOS => {
			'const_dcl' => 1,
			'interface_header' => 2,
			'except_dcl' => 3,
			'module_header' => 6,
			'interface' => 7,
			'struct_type' => 8,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
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
	{#State 40
		DEFAULT => -9
	},
	{#State 41
		DEFAULT => -226
	},
	{#State 42
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'VOID' => 72,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 76,
			'LONG' => 77,
			'STRING' => 78,
			"::" => 79,
			'WSTRING' => 81,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'UNION' => 16,
			'WCHAR' => 59,
			'error' => 143,
			"}" => 145,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'type_spec' => 142,
			'string_type' => 57,
			'struct_header' => 12,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'enum_type' => 63,
			'enum_header' => 20,
			'member_list' => 144,
			'union_header' => 24,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68,
			'wide_string_type' => 73,
			'boolean_type' => 75,
			'integer_type' => 74,
			'signed_short_int' => 80,
			'member' => 146,
			'struct_type' => 82,
			'union_type' => 84,
			'sequence_type' => 86,
			'unsigned_long_int' => 87,
			'template_type_spec' => 88,
			'constr_type_spec' => 89,
			'simple_type_spec' => 90,
			'fixed_pt_type' => 91
		}
	},
	{#State 43
		DEFAULT => -142
	},
	{#State 44
		DEFAULT => -115
	},
	{#State 45
		ACTIONS => {
			"<" => 148,
			'error' => 147
		}
	},
	{#State 46
		DEFAULT => -141
	},
	{#State 47
		ACTIONS => {
			"<" => 150,
			'error' => 149
		}
	},
	{#State 48
		DEFAULT => -117
	},
	{#State 49
		DEFAULT => -122
	},
	{#State 50
		DEFAULT => -120
	},
	{#State 51
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -113
	},
	{#State 52
		DEFAULT => -118
	},
	{#State 53
		DEFAULT => -144
	},
	{#State 54
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
	{#State 55
		DEFAULT => -103
	},
	{#State 56
		ACTIONS => {
			'SHORT' => 159,
			'LONG' => 160
		}
	},
	{#State 57
		DEFAULT => -124
	},
	{#State 58
		DEFAULT => -146
	},
	{#State 59
		DEFAULT => -156
	},
	{#State 60
		DEFAULT => -151
	},
	{#State 61
		DEFAULT => -121
	},
	{#State 62
		DEFAULT => -111
	},
	{#State 63
		DEFAULT => -129
	},
	{#State 64
		DEFAULT => -107
	},
	{#State 65
		DEFAULT => -158
	},
	{#State 66
		DEFAULT => -149
	},
	{#State 67
		DEFAULT => -138
	},
	{#State 68
		DEFAULT => -145
	},
	{#State 69
		DEFAULT => -159
	},
	{#State 70
		DEFAULT => -155
	},
	{#State 71
		DEFAULT => -160
	},
	{#State 72
		DEFAULT => -114
	},
	{#State 73
		DEFAULT => -125
	},
	{#State 74
		DEFAULT => -116
	},
	{#State 75
		DEFAULT => -119
	},
	{#State 76
		DEFAULT => -139
	},
	{#State 77
		ACTIONS => {
			'LONG' => 162,
			'DOUBLE' => 161
		},
		DEFAULT => -147
	},
	{#State 78
		ACTIONS => {
			"<" => 163
		},
		DEFAULT => -207
	},
	{#State 79
		ACTIONS => {
			'error' => 164,
			'IDENTIFIER' => 165
		}
	},
	{#State 80
		DEFAULT => -143
	},
	{#State 81
		ACTIONS => {
			"<" => 166
		},
		DEFAULT => -210
	},
	{#State 82
		DEFAULT => -127
	},
	{#State 83
		DEFAULT => -157
	},
	{#State 84
		DEFAULT => -128
	},
	{#State 85
		DEFAULT => -43
	},
	{#State 86
		DEFAULT => -123
	},
	{#State 87
		DEFAULT => -150
	},
	{#State 88
		DEFAULT => -112
	},
	{#State 89
		DEFAULT => -110
	},
	{#State 90
		DEFAULT => -109
	},
	{#State 91
		DEFAULT => -126
	},
	{#State 92
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'VOID' => 72,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 76,
			'LONG' => 77,
			'STRING' => 78,
			"::" => 79,
			'WSTRING' => 81,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'UNION' => 16,
			'WCHAR' => 59,
			'error' => 167,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'type_spec' => 142,
			'string_type' => 57,
			'struct_header' => 12,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'enum_type' => 63,
			'enum_header' => 20,
			'member_list' => 168,
			'union_header' => 24,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68,
			'wide_string_type' => 73,
			'boolean_type' => 75,
			'integer_type' => 74,
			'signed_short_int' => 80,
			'member' => 146,
			'struct_type' => 82,
			'union_type' => 84,
			'sequence_type' => 86,
			'unsigned_long_int' => 87,
			'template_type_spec' => 88,
			'constr_type_spec' => 89,
			'simple_type_spec' => 90,
			'fixed_pt_type' => 91
		}
	},
	{#State 93
		ACTIONS => {
			";" => 169
		}
	},
	{#State 94
		DEFAULT => -19
	},
	{#State 95
		DEFAULT => -18
	},
	{#State 96
		DEFAULT => -174
	},
	{#State 97
		DEFAULT => -173
	},
	{#State 98
		DEFAULT => -193
	},
	{#State 99
		ACTIONS => {
			'error' => 170,
			'IDENTIFIER' => 172
		},
		GOTOS => {
			'enumerators' => 173,
			'enumerator' => 171
		}
	},
	{#State 100
		DEFAULT => -10
	},
	{#State 101
		DEFAULT => -57
	},
	{#State 102
		DEFAULT => -279
	},
	{#State 103
		DEFAULT => -54
	},
	{#State 104
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -61
	},
	{#State 105
		DEFAULT => -55
	},
	{#State 106
		DEFAULT => -58
	},
	{#State 107
		DEFAULT => -52
	},
	{#State 108
		DEFAULT => -59
	},
	{#State 109
		DEFAULT => -56
	},
	{#State 110
		DEFAULT => -53
	},
	{#State 111
		DEFAULT => -60
	},
	{#State 112
		ACTIONS => {
			'error' => 174,
			'IDENTIFIER' => 175
		}
	},
	{#State 113
		DEFAULT => -228
	},
	{#State 114
		DEFAULT => -227
	},
	{#State 115
		ACTIONS => {
			'error' => 177,
			"(" => 176
		}
	},
	{#State 116
		DEFAULT => -6
	},
	{#State 117
		DEFAULT => -5
	},
	{#State 118
		DEFAULT => -195
	},
	{#State 119
		DEFAULT => -194
	},
	{#State 120
		ACTIONS => {
			"{" => -28
		},
		DEFAULT => -26
	},
	{#State 121
		ACTIONS => {
			"{" => -39,
			":" => 178
		},
		DEFAULT => -25,
		GOTOS => {
			'interface_inheritance_spec' => 179
		}
	},
	{#State 122
		DEFAULT => -235
	},
	{#State 123
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'VOID' => 184,
			'SEQUENCE' => 47,
			'DOUBLE' => 76,
			'LONG' => 77,
			'STRING' => 78,
			"::" => 79,
			'WSTRING' => 81,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'WCHAR' => 59,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'wide_string_type' => 183,
			'integer_type' => 74,
			'boolean_type' => 75,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 180,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'signed_short_int' => 80,
			'string_type' => 181,
			'op_type_spec' => 186,
			'op_param_type_spec' => 185,
			'sequence_type' => 187,
			'base_type_spec' => 182,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'unsigned_long_int' => 87,
			'unsigned_short_int' => 66,
			'fixed_pt_type' => 188,
			'signed_longlong_int' => 68
		}
	},
	{#State 124
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 189
		}
	},
	{#State 125
		DEFAULT => -233
	},
	{#State 126
		ACTIONS => {
			'ATTRIBUTE' => 190
		}
	},
	{#State 127
		ACTIONS => {
			"}" => 191
		}
	},
	{#State 128
		DEFAULT => -22
	},
	{#State 129
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 192
		}
	},
	{#State 130
		DEFAULT => -29
	},
	{#State 131
		ACTIONS => {
			'ONEWAY' => 122,
			'STRUCT' => 5,
			'TYPEDEF' => 11,
			'UNION' => 16,
			'READONLY' => 133,
			'ATTRIBUTE' => -220,
			'CONST' => 22,
			"}" => -30,
			'EXCEPTION' => 23,
			'ENUM' => 28
		},
		DEFAULT => -234,
		GOTOS => {
			'const_dcl' => 129,
			'op_mod' => 123,
			'except_dcl' => 124,
			'op_attribute' => 125,
			'attr_mod' => 126,
			'exports' => 193,
			'export' => 131,
			'struct_type' => 8,
			'op_header' => 132,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 17,
			'op_dcl' => 134,
			'enum_header' => 20,
			'attr_dcl' => 135,
			'type_dcl' => 136,
			'union_header' => 24
		}
	},
	{#State 132
		ACTIONS => {
			'error' => 195,
			"(" => 194
		},
		GOTOS => {
			'parameter_dcls' => 196
		}
	},
	{#State 133
		DEFAULT => -219
	},
	{#State 134
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 197
		}
	},
	{#State 135
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 198
		}
	},
	{#State 136
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 199
		}
	},
	{#State 137
		ACTIONS => {
			"}" => 200
		}
	},
	{#State 138
		DEFAULT => -17
	},
	{#State 139
		ACTIONS => {
			"}" => 201
		}
	},
	{#State 140
		DEFAULT => -16
	},
	{#State 141
		ACTIONS => {
			"}" => 202
		}
	},
	{#State 142
		ACTIONS => {
			'error' => 154,
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'declarators' => 203,
			'declarator' => 153,
			'simple_declarator' => 156,
			'array_declarator' => 157,
			'complex_declarator' => 155
		}
	},
	{#State 143
		ACTIONS => {
			"}" => 204
		}
	},
	{#State 144
		ACTIONS => {
			"}" => 205
		}
	},
	{#State 145
		DEFAULT => -223
	},
	{#State 146
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'VOID' => 72,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 76,
			'LONG' => 77,
			'STRING' => 78,
			"::" => 79,
			'WSTRING' => 81,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'UNION' => 16,
			'WCHAR' => 59,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		DEFAULT => -165,
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'type_spec' => 142,
			'string_type' => 57,
			'struct_header' => 12,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'enum_type' => 63,
			'enum_header' => 20,
			'member_list' => 206,
			'union_header' => 24,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68,
			'wide_string_type' => 73,
			'boolean_type' => 75,
			'integer_type' => 74,
			'signed_short_int' => 80,
			'member' => 146,
			'struct_type' => 82,
			'union_type' => 84,
			'sequence_type' => 86,
			'unsigned_long_int' => 87,
			'template_type_spec' => 88,
			'constr_type_spec' => 89,
			'simple_type_spec' => 90,
			'fixed_pt_type' => 91
		}
	},
	{#State 147
		DEFAULT => -278
	},
	{#State 148
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'CHARACTER_LITERAL' => 207,
			'WIDE_CHARACTER_LITERAL' => 208,
			"::" => 79,
			'INTEGER_LITERAL' => 228,
			"(" => 212,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'FIXED_PT_LITERAL' => 231,
			"+" => 232,
			'error' => 216,
			"-" => 234,
			'WIDE_STRING_LITERAL' => 220,
			'FALSE' => 219,
			"~" => 235,
			'TRUE' => 222
		},
		GOTOS => {
			'string_literal' => 224,
			'primary_expr' => 226,
			'and_expr' => 227,
			'scoped_name' => 209,
			'positive_int_const' => 210,
			'wide_string_literal' => 211,
			'boolean_literal' => 213,
			'mult_expr' => 229,
			'const_exp' => 214,
			'or_expr' => 215,
			'unary_expr' => 233,
			'xor_expr' => 217,
			'shift_expr' => 218,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 149
		DEFAULT => -205
	},
	{#State 150
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'VOID' => 72,
			'SEQUENCE' => 47,
			'DOUBLE' => 76,
			'LONG' => 77,
			'STRING' => 78,
			"::" => 79,
			'WSTRING' => 81,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'WCHAR' => 59,
			'error' => 237,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'wide_string_type' => 73,
			'integer_type' => 74,
			'boolean_type' => 75,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'signed_short_int' => 80,
			'string_type' => 57,
			'sequence_type' => 86,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'unsigned_long_int' => 87,
			'template_type_spec' => 88,
			'unsigned_short_int' => 66,
			'simple_type_spec' => 238,
			'fixed_pt_type' => 91,
			'signed_longlong_int' => 68
		}
	},
	{#State 151
		ACTIONS => {
			'error' => 239,
			'IDENTIFIER' => 240
		}
	},
	{#State 152
		DEFAULT => -108
	},
	{#State 153
		ACTIONS => {
			"," => 241
		},
		DEFAULT => -130
	},
	{#State 154
		ACTIONS => {
			";" => 242,
			"," => 243
		}
	},
	{#State 155
		DEFAULT => -133
	},
	{#State 156
		DEFAULT => -132
	},
	{#State 157
		DEFAULT => -137
	},
	{#State 158
		ACTIONS => {
			"[" => 246
		},
		DEFAULT => -134,
		GOTOS => {
			'fixed_array_sizes' => 244,
			'fixed_array_size' => 245
		}
	},
	{#State 159
		DEFAULT => -152
	},
	{#State 160
		ACTIONS => {
			'LONG' => 247
		},
		DEFAULT => -153
	},
	{#State 161
		DEFAULT => -140
	},
	{#State 162
		DEFAULT => -148
	},
	{#State 163
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'CHARACTER_LITERAL' => 207,
			'WIDE_CHARACTER_LITERAL' => 208,
			"::" => 79,
			'INTEGER_LITERAL' => 228,
			"(" => 212,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'FIXED_PT_LITERAL' => 231,
			"+" => 232,
			'error' => 249,
			"-" => 234,
			'WIDE_STRING_LITERAL' => 220,
			'FALSE' => 219,
			"~" => 235,
			'TRUE' => 222
		},
		GOTOS => {
			'string_literal' => 224,
			'primary_expr' => 226,
			'and_expr' => 227,
			'scoped_name' => 209,
			'positive_int_const' => 248,
			'wide_string_literal' => 211,
			'boolean_literal' => 213,
			'mult_expr' => 229,
			'const_exp' => 214,
			'or_expr' => 215,
			'unary_expr' => 233,
			'xor_expr' => 217,
			'shift_expr' => 218,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 164
		DEFAULT => -45
	},
	{#State 165
		DEFAULT => -44
	},
	{#State 166
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'CHARACTER_LITERAL' => 207,
			'WIDE_CHARACTER_LITERAL' => 208,
			"::" => 79,
			'INTEGER_LITERAL' => 228,
			"(" => 212,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'FIXED_PT_LITERAL' => 231,
			"+" => 232,
			'error' => 251,
			"-" => 234,
			'WIDE_STRING_LITERAL' => 220,
			'FALSE' => 219,
			"~" => 235,
			'TRUE' => 222
		},
		GOTOS => {
			'string_literal' => 224,
			'primary_expr' => 226,
			'and_expr' => 227,
			'scoped_name' => 209,
			'positive_int_const' => 250,
			'wide_string_literal' => 211,
			'boolean_literal' => 213,
			'mult_expr' => 229,
			'const_exp' => 214,
			'or_expr' => 215,
			'unary_expr' => 233,
			'xor_expr' => 217,
			'shift_expr' => 218,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 167
		ACTIONS => {
			"}" => 252
		}
	},
	{#State 168
		ACTIONS => {
			"}" => 253
		}
	},
	{#State 169
		DEFAULT => -11
	},
	{#State 170
		ACTIONS => {
			"}" => 254
		}
	},
	{#State 171
		ACTIONS => {
			";" => 255,
			"," => 256
		},
		DEFAULT => -196
	},
	{#State 172
		DEFAULT => -200
	},
	{#State 173
		ACTIONS => {
			"}" => 257
		}
	},
	{#State 174
		DEFAULT => -51
	},
	{#State 175
		ACTIONS => {
			'error' => 258,
			"=" => 259
		}
	},
	{#State 176
		ACTIONS => {
			'CHAR' => 70,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'error' => 263,
			'LONG' => 267,
			"::" => 79,
			'ENUM' => 28,
			'UNSIGNED' => 56
		},
		GOTOS => {
			'switch_type_spec' => 264,
			'unsigned_int' => 43,
			'signed_int' => 46,
			'integer_type' => 266,
			'boolean_type' => 265,
			'unsigned_longlong_int' => 60,
			'char_type' => 260,
			'enum_type' => 262,
			'unsigned_long_int' => 87,
			'scoped_name' => 261,
			'enum_header' => 20,
			'signed_long_int' => 53,
			'unsigned_short_int' => 66,
			'signed_short_int' => 80,
			'signed_longlong_int' => 68
		}
	},
	{#State 177
		DEFAULT => -172
	},
	{#State 178
		ACTIONS => {
			'error' => 269,
			'IDENTIFIER' => 85,
			"::" => 79
		},
		GOTOS => {
			'scoped_name' => 268,
			'interface_names' => 271,
			'interface_name' => 270
		}
	},
	{#State 179
		DEFAULT => -27
	},
	{#State 180
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -274
	},
	{#State 181
		DEFAULT => -271
	},
	{#State 182
		DEFAULT => -270
	},
	{#State 183
		DEFAULT => -272
	},
	{#State 184
		DEFAULT => -237
	},
	{#State 185
		DEFAULT => -236
	},
	{#State 186
		ACTIONS => {
			'error' => 272,
			'IDENTIFIER' => 273
		}
	},
	{#State 187
		DEFAULT => -238
	},
	{#State 188
		DEFAULT => -273
	},
	{#State 189
		DEFAULT => -34
	},
	{#State 190
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'VOID' => 276,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 76,
			'LONG' => 77,
			'STRING' => 78,
			"::" => 79,
			'WSTRING' => 81,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'UNION' => 16,
			'WCHAR' => 59,
			'error' => 274,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'wide_string_type' => 183,
			'integer_type' => 74,
			'boolean_type' => 75,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 180,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'signed_short_int' => 80,
			'string_type' => 181,
			'op_param_type_spec' => 277,
			'struct_type' => 82,
			'union_type' => 84,
			'struct_header' => 12,
			'sequence_type' => 278,
			'base_type_spec' => 182,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'enum_type' => 63,
			'unsigned_long_int' => 87,
			'param_type_spec' => 275,
			'enum_header' => 20,
			'constr_type_spec' => 279,
			'unsigned_short_int' => 66,
			'union_header' => 24,
			'fixed_pt_type' => 188,
			'signed_longlong_int' => 68
		}
	},
	{#State 191
		DEFAULT => -24
	},
	{#State 192
		DEFAULT => -33
	},
	{#State 193
		DEFAULT => -31
	},
	{#State 194
		ACTIONS => {
			'CHAR' => -252,
			'OBJECT' => -252,
			'FIXED' => -252,
			'VOID' => -252,
			'IN' => 280,
			'SEQUENCE' => -252,
			'STRUCT' => -252,
			'DOUBLE' => -252,
			'LONG' => -252,
			'STRING' => -252,
			"::" => -252,
			'WSTRING' => -252,
			"..." => 281,
			'UNSIGNED' => -252,
			'SHORT' => -252,
			")" => 286,
			'OUT' => 287,
			'BOOLEAN' => -252,
			'IDENTIFIER' => -252,
			'UNION' => -252,
			'WCHAR' => -252,
			'error' => 282,
			'INOUT' => 283,
			'OCTET' => -252,
			'FLOAT' => -252,
			'ENUM' => -252,
			'ANY' => -252
		},
		GOTOS => {
			'param_dcl' => 288,
			'param_dcls' => 285,
			'param_attribute' => 284
		}
	},
	{#State 195
		DEFAULT => -230
	},
	{#State 196
		ACTIONS => {
			'RAISES' => 290
		},
		DEFAULT => -256,
		GOTOS => {
			'raises_expr' => 289
		}
	},
	{#State 197
		DEFAULT => -36
	},
	{#State 198
		DEFAULT => -35
	},
	{#State 199
		DEFAULT => -32
	},
	{#State 200
		DEFAULT => -23
	},
	{#State 201
		DEFAULT => -15
	},
	{#State 202
		DEFAULT => -14
	},
	{#State 203
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 291
		}
	},
	{#State 204
		DEFAULT => -225
	},
	{#State 205
		DEFAULT => -224
	},
	{#State 206
		DEFAULT => -166
	},
	{#State 207
		DEFAULT => -91
	},
	{#State 208
		DEFAULT => -92
	},
	{#State 209
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -84
	},
	{#State 210
		ACTIONS => {
			"," => 292
		}
	},
	{#State 211
		DEFAULT => -90
	},
	{#State 212
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'CHARACTER_LITERAL' => 207,
			'WIDE_CHARACTER_LITERAL' => 208,
			"::" => 79,
			'INTEGER_LITERAL' => 228,
			"(" => 212,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'FIXED_PT_LITERAL' => 231,
			"+" => 232,
			'error' => 294,
			"-" => 234,
			'WIDE_STRING_LITERAL' => 220,
			'FALSE' => 219,
			"~" => 235,
			'TRUE' => 222
		},
		GOTOS => {
			'mult_expr' => 229,
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'const_exp' => 293,
			'and_expr' => 227,
			'or_expr' => 215,
			'unary_expr' => 233,
			'scoped_name' => 209,
			'xor_expr' => 217,
			'shift_expr' => 218,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 213
		DEFAULT => -95
	},
	{#State 214
		DEFAULT => -102
	},
	{#State 215
		ACTIONS => {
			"|" => 295
		},
		DEFAULT => -62
	},
	{#State 216
		ACTIONS => {
			">" => 296
		}
	},
	{#State 217
		ACTIONS => {
			"^" => 297
		},
		DEFAULT => -63
	},
	{#State 218
		ACTIONS => {
			"<<" => 298,
			">>" => 299
		},
		DEFAULT => -67
	},
	{#State 219
		DEFAULT => -101
	},
	{#State 220
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 220
		},
		DEFAULT => -98,
		GOTOS => {
			'wide_string_literal' => 300
		}
	},
	{#State 221
		DEFAULT => -85
	},
	{#State 222
		DEFAULT => -100
	},
	{#State 223
		ACTIONS => {
			"+" => 301,
			"-" => 302
		},
		DEFAULT => -69
	},
	{#State 224
		DEFAULT => -89
	},
	{#State 225
		DEFAULT => -94
	},
	{#State 226
		DEFAULT => -80
	},
	{#State 227
		ACTIONS => {
			"&" => 303
		},
		DEFAULT => -65
	},
	{#State 228
		DEFAULT => -88
	},
	{#State 229
		ACTIONS => {
			"%" => 305,
			"*" => 304,
			"/" => 306
		},
		DEFAULT => -72
	},
	{#State 230
		ACTIONS => {
			'STRING_LITERAL' => 230
		},
		DEFAULT => -96,
		GOTOS => {
			'string_literal' => 307
		}
	},
	{#State 231
		DEFAULT => -93
	},
	{#State 232
		DEFAULT => -82
	},
	{#State 233
		DEFAULT => -75
	},
	{#State 234
		DEFAULT => -81
	},
	{#State 235
		DEFAULT => -83
	},
	{#State 236
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'string_literal' => 224,
			'boolean_literal' => 213,
			'scoped_name' => 209,
			'primary_expr' => 308,
			'literal' => 221,
			'wide_string_literal' => 211
		}
	},
	{#State 237
		ACTIONS => {
			">" => 309
		}
	},
	{#State 238
		ACTIONS => {
			">" => 311,
			"," => 310
		}
	},
	{#State 239
		DEFAULT => -47
	},
	{#State 240
		DEFAULT => -46
	},
	{#State 241
		ACTIONS => {
			'error' => 154,
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'declarators' => 312,
			'declarator' => 153,
			'simple_declarator' => 156,
			'array_declarator' => 157,
			'complex_declarator' => 155
		}
	},
	{#State 242
		DEFAULT => -136
	},
	{#State 243
		DEFAULT => -135
	},
	{#State 244
		DEFAULT => -212
	},
	{#State 245
		ACTIONS => {
			"[" => 246
		},
		DEFAULT => -213,
		GOTOS => {
			'fixed_array_sizes' => 313,
			'fixed_array_size' => 245
		}
	},
	{#State 246
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'CHARACTER_LITERAL' => 207,
			'WIDE_CHARACTER_LITERAL' => 208,
			"::" => 79,
			'INTEGER_LITERAL' => 228,
			"(" => 212,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'FIXED_PT_LITERAL' => 231,
			"+" => 232,
			'error' => 315,
			"-" => 234,
			'WIDE_STRING_LITERAL' => 220,
			'FALSE' => 219,
			"~" => 235,
			'TRUE' => 222
		},
		GOTOS => {
			'string_literal' => 224,
			'primary_expr' => 226,
			'and_expr' => 227,
			'scoped_name' => 209,
			'positive_int_const' => 314,
			'wide_string_literal' => 211,
			'boolean_literal' => 213,
			'mult_expr' => 229,
			'const_exp' => 214,
			'or_expr' => 215,
			'unary_expr' => 233,
			'xor_expr' => 217,
			'shift_expr' => 218,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 247
		DEFAULT => -154
	},
	{#State 248
		ACTIONS => {
			">" => 316
		}
	},
	{#State 249
		ACTIONS => {
			">" => 317
		}
	},
	{#State 250
		ACTIONS => {
			">" => 318
		}
	},
	{#State 251
		ACTIONS => {
			">" => 319
		}
	},
	{#State 252
		DEFAULT => -162
	},
	{#State 253
		DEFAULT => -161
	},
	{#State 254
		DEFAULT => -192
	},
	{#State 255
		DEFAULT => -199
	},
	{#State 256
		ACTIONS => {
			'IDENTIFIER' => 172
		},
		DEFAULT => -198,
		GOTOS => {
			'enumerators' => 320,
			'enumerator' => 171
		}
	},
	{#State 257
		DEFAULT => -191
	},
	{#State 258
		DEFAULT => -50
	},
	{#State 259
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'CHARACTER_LITERAL' => 207,
			'WIDE_CHARACTER_LITERAL' => 208,
			"::" => 79,
			'INTEGER_LITERAL' => 228,
			"(" => 212,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'FIXED_PT_LITERAL' => 231,
			"+" => 232,
			'error' => 322,
			"-" => 234,
			'WIDE_STRING_LITERAL' => 220,
			'FALSE' => 219,
			"~" => 235,
			'TRUE' => 222
		},
		GOTOS => {
			'mult_expr' => 229,
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'const_exp' => 321,
			'and_expr' => 227,
			'or_expr' => 215,
			'unary_expr' => 233,
			'scoped_name' => 209,
			'xor_expr' => 217,
			'shift_expr' => 218,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 260
		DEFAULT => -176
	},
	{#State 261
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -179
	},
	{#State 262
		DEFAULT => -178
	},
	{#State 263
		ACTIONS => {
			")" => 323
		}
	},
	{#State 264
		ACTIONS => {
			")" => 324
		}
	},
	{#State 265
		DEFAULT => -177
	},
	{#State 266
		DEFAULT => -175
	},
	{#State 267
		ACTIONS => {
			'LONG' => 162
		},
		DEFAULT => -147
	},
	{#State 268
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -42
	},
	{#State 269
		DEFAULT => -38
	},
	{#State 270
		ACTIONS => {
			"," => 325
		},
		DEFAULT => -40
	},
	{#State 271
		DEFAULT => -37
	},
	{#State 272
		DEFAULT => -232
	},
	{#State 273
		DEFAULT => -231
	},
	{#State 274
		DEFAULT => -218
	},
	{#State 275
		ACTIONS => {
			'error' => 154,
			'IDENTIFIER' => 328
		},
		GOTOS => {
			'simple_declarators' => 327,
			'simple_declarator' => 326
		}
	},
	{#State 276
		DEFAULT => -267
	},
	{#State 277
		DEFAULT => -266
	},
	{#State 278
		DEFAULT => -268
	},
	{#State 279
		DEFAULT => -269
	},
	{#State 280
		DEFAULT => -249
	},
	{#State 281
		ACTIONS => {
			")" => 329
		}
	},
	{#State 282
		ACTIONS => {
			")" => 330
		}
	},
	{#State 283
		DEFAULT => -251
	},
	{#State 284
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'VOID' => 276,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 76,
			'LONG' => 77,
			'STRING' => 78,
			"::" => 79,
			'WSTRING' => 81,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'UNION' => 16,
			'WCHAR' => 59,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'wide_string_type' => 183,
			'integer_type' => 74,
			'boolean_type' => 75,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 180,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'signed_short_int' => 80,
			'string_type' => 181,
			'op_param_type_spec' => 277,
			'struct_type' => 82,
			'union_type' => 84,
			'struct_header' => 12,
			'sequence_type' => 278,
			'base_type_spec' => 182,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'enum_type' => 63,
			'unsigned_long_int' => 87,
			'param_type_spec' => 331,
			'enum_header' => 20,
			'constr_type_spec' => 279,
			'unsigned_short_int' => 66,
			'union_header' => 24,
			'fixed_pt_type' => 188,
			'signed_longlong_int' => 68
		}
	},
	{#State 285
		ACTIONS => {
			")" => 333,
			"," => 332
		}
	},
	{#State 286
		DEFAULT => -242
	},
	{#State 287
		DEFAULT => -250
	},
	{#State 288
		ACTIONS => {
			";" => 334
		},
		DEFAULT => -245
	},
	{#State 289
		ACTIONS => {
			'CONTEXT' => 335
		},
		DEFAULT => -263,
		GOTOS => {
			'context_expr' => 336
		}
	},
	{#State 290
		ACTIONS => {
			'error' => 338,
			"(" => 337
		}
	},
	{#State 291
		DEFAULT => -167
	},
	{#State 292
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'CHARACTER_LITERAL' => 207,
			'WIDE_CHARACTER_LITERAL' => 208,
			"::" => 79,
			'INTEGER_LITERAL' => 228,
			"(" => 212,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'FIXED_PT_LITERAL' => 231,
			"+" => 232,
			'error' => 340,
			"-" => 234,
			'WIDE_STRING_LITERAL' => 220,
			'FALSE' => 219,
			"~" => 235,
			'TRUE' => 222
		},
		GOTOS => {
			'string_literal' => 224,
			'primary_expr' => 226,
			'and_expr' => 227,
			'scoped_name' => 209,
			'positive_int_const' => 339,
			'wide_string_literal' => 211,
			'boolean_literal' => 213,
			'mult_expr' => 229,
			'const_exp' => 214,
			'or_expr' => 215,
			'unary_expr' => 233,
			'xor_expr' => 217,
			'shift_expr' => 218,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 293
		ACTIONS => {
			")" => 341
		}
	},
	{#State 294
		ACTIONS => {
			")" => 342
		}
	},
	{#State 295
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			"+" => 232,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"-" => 234,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"~" => 235,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'mult_expr' => 229,
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'and_expr' => 227,
			'unary_expr' => 233,
			'scoped_name' => 209,
			'xor_expr' => 343,
			'shift_expr' => 218,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 296
		DEFAULT => -277
	},
	{#State 297
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			"+" => 232,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"-" => 234,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"~" => 235,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'mult_expr' => 229,
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'and_expr' => 344,
			'unary_expr' => 233,
			'scoped_name' => 209,
			'shift_expr' => 218,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 298
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			"+" => 232,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"-" => 234,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"~" => 235,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'mult_expr' => 229,
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'unary_expr' => 233,
			'scoped_name' => 209,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 345
		}
	},
	{#State 299
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			"+" => 232,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"-" => 234,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"~" => 235,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'mult_expr' => 229,
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'unary_expr' => 233,
			'scoped_name' => 209,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 346
		}
	},
	{#State 300
		DEFAULT => -99
	},
	{#State 301
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			"+" => 232,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"-" => 234,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"~" => 235,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'mult_expr' => 347,
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'unary_expr' => 233,
			'scoped_name' => 209,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236
		}
	},
	{#State 302
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			"+" => 232,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"-" => 234,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"~" => 235,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'mult_expr' => 348,
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'unary_expr' => 233,
			'scoped_name' => 209,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236
		}
	},
	{#State 303
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			"+" => 232,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"-" => 234,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"~" => 235,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'mult_expr' => 229,
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'unary_expr' => 233,
			'scoped_name' => 209,
			'shift_expr' => 349,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 304
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			"+" => 232,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"-" => 234,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"~" => 235,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'unary_expr' => 350,
			'scoped_name' => 209,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236
		}
	},
	{#State 305
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			"+" => 232,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"-" => 234,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"~" => 235,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'unary_expr' => 351,
			'scoped_name' => 209,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236
		}
	},
	{#State 306
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 207,
			"+" => 232,
			'FIXED_PT_LITERAL' => 231,
			'WIDE_CHARACTER_LITERAL' => 208,
			"-" => 234,
			"::" => 79,
			'FALSE' => 219,
			'WIDE_STRING_LITERAL' => 220,
			'INTEGER_LITERAL' => 228,
			"~" => 235,
			"(" => 212,
			'TRUE' => 222
		},
		GOTOS => {
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'unary_expr' => 352,
			'scoped_name' => 209,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236
		}
	},
	{#State 307
		DEFAULT => -97
	},
	{#State 308
		DEFAULT => -79
	},
	{#State 309
		DEFAULT => -204
	},
	{#State 310
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'CHARACTER_LITERAL' => 207,
			'WIDE_CHARACTER_LITERAL' => 208,
			"::" => 79,
			'INTEGER_LITERAL' => 228,
			"(" => 212,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'FIXED_PT_LITERAL' => 231,
			"+" => 232,
			'error' => 354,
			"-" => 234,
			'WIDE_STRING_LITERAL' => 220,
			'FALSE' => 219,
			"~" => 235,
			'TRUE' => 222
		},
		GOTOS => {
			'string_literal' => 224,
			'primary_expr' => 226,
			'and_expr' => 227,
			'scoped_name' => 209,
			'positive_int_const' => 353,
			'wide_string_literal' => 211,
			'boolean_literal' => 213,
			'mult_expr' => 229,
			'const_exp' => 214,
			'or_expr' => 215,
			'unary_expr' => 233,
			'xor_expr' => 217,
			'shift_expr' => 218,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 311
		DEFAULT => -203
	},
	{#State 312
		DEFAULT => -131
	},
	{#State 313
		DEFAULT => -214
	},
	{#State 314
		ACTIONS => {
			"]" => 355
		}
	},
	{#State 315
		ACTIONS => {
			"]" => 356
		}
	},
	{#State 316
		DEFAULT => -206
	},
	{#State 317
		DEFAULT => -208
	},
	{#State 318
		DEFAULT => -209
	},
	{#State 319
		DEFAULT => -211
	},
	{#State 320
		DEFAULT => -197
	},
	{#State 321
		DEFAULT => -48
	},
	{#State 322
		DEFAULT => -49
	},
	{#State 323
		DEFAULT => -171
	},
	{#State 324
		ACTIONS => {
			"{" => 358,
			'error' => 357
		}
	},
	{#State 325
		ACTIONS => {
			'IDENTIFIER' => 85,
			"::" => 79
		},
		GOTOS => {
			'scoped_name' => 268,
			'interface_names' => 359,
			'interface_name' => 270
		}
	},
	{#State 326
		ACTIONS => {
			"," => 360
		},
		DEFAULT => -221
	},
	{#State 327
		DEFAULT => -217
	},
	{#State 328
		DEFAULT => -134
	},
	{#State 329
		DEFAULT => -243
	},
	{#State 330
		DEFAULT => -244
	},
	{#State 331
		ACTIONS => {
			'error' => 154,
			'IDENTIFIER' => 328
		},
		GOTOS => {
			'simple_declarator' => 361
		}
	},
	{#State 332
		ACTIONS => {
			'IN' => 280,
			"..." => 362,
			")" => 363,
			'OUT' => 287,
			'INOUT' => 283
		},
		DEFAULT => -252,
		GOTOS => {
			'param_dcl' => 364,
			'param_attribute' => 284
		}
	},
	{#State 333
		DEFAULT => -239
	},
	{#State 334
		DEFAULT => -247
	},
	{#State 335
		ACTIONS => {
			'error' => 366,
			"(" => 365
		}
	},
	{#State 336
		DEFAULT => -229
	},
	{#State 337
		ACTIONS => {
			'error' => 368,
			'IDENTIFIER' => 85,
			"::" => 79
		},
		GOTOS => {
			'scoped_name' => 367,
			'exception_names' => 369,
			'exception_name' => 370
		}
	},
	{#State 338
		DEFAULT => -255
	},
	{#State 339
		ACTIONS => {
			">" => 371
		}
	},
	{#State 340
		ACTIONS => {
			">" => 372
		}
	},
	{#State 341
		DEFAULT => -86
	},
	{#State 342
		DEFAULT => -87
	},
	{#State 343
		ACTIONS => {
			"^" => 297
		},
		DEFAULT => -64
	},
	{#State 344
		ACTIONS => {
			"&" => 303
		},
		DEFAULT => -66
	},
	{#State 345
		ACTIONS => {
			"+" => 301,
			"-" => 302
		},
		DEFAULT => -71
	},
	{#State 346
		ACTIONS => {
			"+" => 301,
			"-" => 302
		},
		DEFAULT => -70
	},
	{#State 347
		ACTIONS => {
			"%" => 305,
			"*" => 304,
			"/" => 306
		},
		DEFAULT => -73
	},
	{#State 348
		ACTIONS => {
			"%" => 305,
			"*" => 304,
			"/" => 306
		},
		DEFAULT => -74
	},
	{#State 349
		ACTIONS => {
			"<<" => 298,
			">>" => 299
		},
		DEFAULT => -68
	},
	{#State 350
		DEFAULT => -76
	},
	{#State 351
		DEFAULT => -78
	},
	{#State 352
		DEFAULT => -77
	},
	{#State 353
		ACTIONS => {
			">" => 373
		}
	},
	{#State 354
		ACTIONS => {
			">" => 374
		}
	},
	{#State 355
		DEFAULT => -215
	},
	{#State 356
		DEFAULT => -216
	},
	{#State 357
		DEFAULT => -170
	},
	{#State 358
		ACTIONS => {
			'error' => 378,
			'CASE' => 375,
			'DEFAULT' => 377
		},
		GOTOS => {
			'case_labels' => 380,
			'switch_body' => 379,
			'case' => 376,
			'case_label' => 381
		}
	},
	{#State 359
		DEFAULT => -41
	},
	{#State 360
		ACTIONS => {
			'error' => 154,
			'IDENTIFIER' => 328
		},
		GOTOS => {
			'simple_declarators' => 382,
			'simple_declarator' => 326
		}
	},
	{#State 361
		DEFAULT => -248
	},
	{#State 362
		ACTIONS => {
			")" => 383
		}
	},
	{#State 363
		DEFAULT => -241
	},
	{#State 364
		DEFAULT => -246
	},
	{#State 365
		ACTIONS => {
			'error' => 384,
			'STRING_LITERAL' => 230
		},
		GOTOS => {
			'string_literal' => 385,
			'string_literals' => 386
		}
	},
	{#State 366
		DEFAULT => -262
	},
	{#State 367
		ACTIONS => {
			"::" => 151
		},
		DEFAULT => -259
	},
	{#State 368
		ACTIONS => {
			")" => 387
		}
	},
	{#State 369
		ACTIONS => {
			")" => 388
		}
	},
	{#State 370
		ACTIONS => {
			"," => 389
		},
		DEFAULT => -257
	},
	{#State 371
		DEFAULT => -275
	},
	{#State 372
		DEFAULT => -276
	},
	{#State 373
		DEFAULT => -201
	},
	{#State 374
		DEFAULT => -202
	},
	{#State 375
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 225,
			'CHARACTER_LITERAL' => 207,
			'WIDE_CHARACTER_LITERAL' => 208,
			"::" => 79,
			'INTEGER_LITERAL' => 228,
			"(" => 212,
			'IDENTIFIER' => 85,
			'STRING_LITERAL' => 230,
			'FIXED_PT_LITERAL' => 231,
			"+" => 232,
			'error' => 391,
			"-" => 234,
			'WIDE_STRING_LITERAL' => 220,
			'FALSE' => 219,
			"~" => 235,
			'TRUE' => 222
		},
		GOTOS => {
			'mult_expr' => 229,
			'string_literal' => 224,
			'boolean_literal' => 213,
			'primary_expr' => 226,
			'const_exp' => 390,
			'and_expr' => 227,
			'or_expr' => 215,
			'unary_expr' => 233,
			'scoped_name' => 209,
			'xor_expr' => 217,
			'shift_expr' => 218,
			'wide_string_literal' => 211,
			'literal' => 221,
			'unary_operator' => 236,
			'add_expr' => 223
		}
	},
	{#State 376
		ACTIONS => {
			'CASE' => 375,
			'DEFAULT' => 377
		},
		DEFAULT => -180,
		GOTOS => {
			'case_labels' => 380,
			'switch_body' => 392,
			'case' => 376,
			'case_label' => 381
		}
	},
	{#State 377
		ACTIONS => {
			'error' => 393,
			":" => 394
		}
	},
	{#State 378
		ACTIONS => {
			"}" => 395
		}
	},
	{#State 379
		ACTIONS => {
			"}" => 396
		}
	},
	{#State 380
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'VOID' => 72,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 76,
			'LONG' => 77,
			'STRING' => 78,
			"::" => 79,
			'WSTRING' => 81,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 83,
			'IDENTIFIER' => 85,
			'UNION' => 16,
			'WCHAR' => 59,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'type_spec' => 397,
			'string_type' => 57,
			'struct_header' => 12,
			'element_spec' => 398,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'enum_type' => 63,
			'enum_header' => 20,
			'union_header' => 24,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68,
			'wide_string_type' => 73,
			'boolean_type' => 75,
			'integer_type' => 74,
			'signed_short_int' => 80,
			'struct_type' => 82,
			'union_type' => 84,
			'sequence_type' => 86,
			'unsigned_long_int' => 87,
			'template_type_spec' => 88,
			'constr_type_spec' => 89,
			'simple_type_spec' => 90,
			'fixed_pt_type' => 91
		}
	},
	{#State 381
		ACTIONS => {
			'CASE' => 375,
			'DEFAULT' => 377
		},
		DEFAULT => -183,
		GOTOS => {
			'case_labels' => 399,
			'case_label' => 381
		}
	},
	{#State 382
		DEFAULT => -222
	},
	{#State 383
		DEFAULT => -240
	},
	{#State 384
		ACTIONS => {
			")" => 400
		}
	},
	{#State 385
		ACTIONS => {
			"," => 401
		},
		DEFAULT => -264
	},
	{#State 386
		ACTIONS => {
			")" => 402
		}
	},
	{#State 387
		DEFAULT => -254
	},
	{#State 388
		DEFAULT => -253
	},
	{#State 389
		ACTIONS => {
			'IDENTIFIER' => 85,
			"::" => 79
		},
		GOTOS => {
			'scoped_name' => 367,
			'exception_names' => 403,
			'exception_name' => 370
		}
	},
	{#State 390
		ACTIONS => {
			'error' => 404,
			":" => 405
		}
	},
	{#State 391
		DEFAULT => -187
	},
	{#State 392
		DEFAULT => -181
	},
	{#State 393
		DEFAULT => -189
	},
	{#State 394
		DEFAULT => -188
	},
	{#State 395
		DEFAULT => -169
	},
	{#State 396
		DEFAULT => -168
	},
	{#State 397
		ACTIONS => {
			'error' => 154,
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'declarator' => 406,
			'simple_declarator' => 156,
			'array_declarator' => 157,
			'complex_declarator' => 155
		}
	},
	{#State 398
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 407
		}
	},
	{#State 399
		DEFAULT => -184
	},
	{#State 400
		DEFAULT => -261
	},
	{#State 401
		ACTIONS => {
			'STRING_LITERAL' => 230
		},
		GOTOS => {
			'string_literal' => 385,
			'string_literals' => 408
		}
	},
	{#State 402
		DEFAULT => -260
	},
	{#State 403
		DEFAULT => -258
	},
	{#State 404
		DEFAULT => -186
	},
	{#State 405
		DEFAULT => -185
	},
	{#State 406
		DEFAULT => -190
	},
	{#State 407
		DEFAULT => -182
	},
	{#State 408
		DEFAULT => -265
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
#line 59 "parser21.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 0,
sub
#line 65 "parser21.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 69 "parser21.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 76 "parser21.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 80 "parser21.yp"
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
		 'definition', 3,
sub
#line 99 "parser21.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 12
		 'check_semicolon', 1, undef
	],
	[#Rule 13
		 'check_semicolon', 1,
sub
#line 113 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 14
		 'module', 4,
sub
#line 122 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 15
		 'module', 4,
sub
#line 129 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 16
		 'module', 3,
sub
#line 135 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 17
		 'module', 3,
sub
#line 141 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 18
		 'module_header', 2,
sub
#line 150 "parser21.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 156 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 20
		 'interface', 1, undef
	],
	[#Rule 21
		 'interface', 1, undef
	],
	[#Rule 22
		 'interface_dcl', 3,
sub
#line 173 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 23
		 'interface_dcl', 4,
sub
#line 181 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 189 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 25
		 'forward_dcl', 2,
sub
#line 200 "parser21.yp"
{
			new ForwardRegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 26
		 'forward_dcl', 2,
sub
#line 206 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 27
		 'interface_header', 3,
sub
#line 215 "parser21.yp"
{
			new RegularInterface($_[0],
					'idf'					=>	$_[2],
					'inheritance'			=>	$_[3]
			);
		}
	],
	[#Rule 28
		 'interface_header', 2,
sub
#line 222 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 29
		 'interface_body', 1, undef
	],
	[#Rule 30
		 'exports', 1,
sub
#line 236 "parser21.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 31
		 'exports', 2,
sub
#line 240 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 32
		 'export', 2, undef
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
		 'interface_inheritance_spec', 2,
sub
#line 263 "parser21.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'		=>	$_[2]
			);
		}
	],
	[#Rule 38
		 'interface_inheritance_spec', 2,
sub
#line 269 "parser21.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 39
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 40
		 'interface_names', 1,
sub
#line 279 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 41
		 'interface_names', 3,
sub
#line 283 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 42
		 'interface_name', 1,
sub
#line 291 "parser21.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 43
		 'scoped_name', 1, undef
	],
	[#Rule 44
		 'scoped_name', 2,
sub
#line 301 "parser21.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 45
		 'scoped_name', 2,
sub
#line 305 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 46
		 'scoped_name', 3,
sub
#line 311 "parser21.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 47
		 'scoped_name', 3,
sub
#line 315 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 48
		 'const_dcl', 5,
sub
#line 325 "parser21.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 49
		 'const_dcl', 5,
sub
#line 333 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 50
		 'const_dcl', 4,
sub
#line 338 "parser21.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 51
		 'const_dcl', 3,
sub
#line 343 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 52
		 'const_dcl', 2,
sub
#line 348 "parser21.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 53
		 'const_type', 1, undef
	],
	[#Rule 54
		 'const_type', 1, undef
	],
	[#Rule 55
		 'const_type', 1, undef
	],
	[#Rule 56
		 'const_type', 1, undef
	],
	[#Rule 57
		 'const_type', 1, undef
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
		 'const_type', 1,
sub
#line 373 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 62
		 'const_exp', 1, undef
	],
	[#Rule 63
		 'or_expr', 1, undef
	],
	[#Rule 64
		 'or_expr', 3,
sub
#line 389 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 65
		 'xor_expr', 1, undef
	],
	[#Rule 66
		 'xor_expr', 3,
sub
#line 399 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 67
		 'and_expr', 1, undef
	],
	[#Rule 68
		 'and_expr', 3,
sub
#line 409 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 69
		 'shift_expr', 1, undef
	],
	[#Rule 70
		 'shift_expr', 3,
sub
#line 419 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 71
		 'shift_expr', 3,
sub
#line 423 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 72
		 'add_expr', 1, undef
	],
	[#Rule 73
		 'add_expr', 3,
sub
#line 433 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 74
		 'add_expr', 3,
sub
#line 437 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 75
		 'mult_expr', 1, undef
	],
	[#Rule 76
		 'mult_expr', 3,
sub
#line 447 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 77
		 'mult_expr', 3,
sub
#line 451 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 78
		 'mult_expr', 3,
sub
#line 455 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 79
		 'unary_expr', 2,
sub
#line 463 "parser21.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 80
		 'unary_expr', 1, undef
	],
	[#Rule 81
		 'unary_operator', 1, undef
	],
	[#Rule 82
		 'unary_operator', 1, undef
	],
	[#Rule 83
		 'unary_operator', 1, undef
	],
	[#Rule 84
		 'primary_expr', 1,
sub
#line 483 "parser21.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 85
		 'primary_expr', 1,
sub
#line 489 "parser21.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 86
		 'primary_expr', 3,
sub
#line 493 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 87
		 'primary_expr', 3,
sub
#line 497 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 88
		 'literal', 1,
sub
#line 506 "parser21.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 89
		 'literal', 1,
sub
#line 513 "parser21.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 90
		 'literal', 1,
sub
#line 519 "parser21.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 91
		 'literal', 1,
sub
#line 525 "parser21.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 92
		 'literal', 1,
sub
#line 531 "parser21.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 93
		 'literal', 1,
sub
#line 537 "parser21.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 94
		 'literal', 1,
sub
#line 544 "parser21.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 95
		 'literal', 1, undef
	],
	[#Rule 96
		 'string_literal', 1, undef
	],
	[#Rule 97
		 'string_literal', 2,
sub
#line 558 "parser21.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 98
		 'wide_string_literal', 1, undef
	],
	[#Rule 99
		 'wide_string_literal', 2,
sub
#line 567 "parser21.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 100
		 'boolean_literal', 1,
sub
#line 575 "parser21.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 101
		 'boolean_literal', 1,
sub
#line 581 "parser21.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 102
		 'positive_int_const', 1,
sub
#line 591 "parser21.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 103
		 'type_dcl', 2,
sub
#line 601 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 104
		 'type_dcl', 1, undef
	],
	[#Rule 105
		 'type_dcl', 1, undef
	],
	[#Rule 106
		 'type_dcl', 1, undef
	],
	[#Rule 107
		 'type_dcl', 2,
sub
#line 611 "parser21.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 108
		 'type_declarator', 2,
sub
#line 620 "parser21.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 109
		 'type_spec', 1, undef
	],
	[#Rule 110
		 'type_spec', 1, undef
	],
	[#Rule 111
		 'simple_type_spec', 1, undef
	],
	[#Rule 112
		 'simple_type_spec', 1, undef
	],
	[#Rule 113
		 'simple_type_spec', 1,
sub
#line 643 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 114
		 'simple_type_spec', 1,
sub
#line 647 "parser21.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 115
		 'base_type_spec', 1, undef
	],
	[#Rule 116
		 'base_type_spec', 1, undef
	],
	[#Rule 117
		 'base_type_spec', 1, undef
	],
	[#Rule 118
		 'base_type_spec', 1, undef
	],
	[#Rule 119
		 'base_type_spec', 1, undef
	],
	[#Rule 120
		 'base_type_spec', 1, undef
	],
	[#Rule 121
		 'base_type_spec', 1, undef
	],
	[#Rule 122
		 'base_type_spec', 1, undef
	],
	[#Rule 123
		 'template_type_spec', 1, undef
	],
	[#Rule 124
		 'template_type_spec', 1, undef
	],
	[#Rule 125
		 'template_type_spec', 1, undef
	],
	[#Rule 126
		 'template_type_spec', 1, undef
	],
	[#Rule 127
		 'constr_type_spec', 1, undef
	],
	[#Rule 128
		 'constr_type_spec', 1, undef
	],
	[#Rule 129
		 'constr_type_spec', 1, undef
	],
	[#Rule 130
		 'declarators', 1,
sub
#line 700 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 131
		 'declarators', 3,
sub
#line 704 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 132
		 'declarator', 1,
sub
#line 713 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 133
		 'declarator', 1, undef
	],
	[#Rule 134
		 'simple_declarator', 1, undef
	],
	[#Rule 135
		 'simple_declarator', 2,
sub
#line 725 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 136
		 'simple_declarator', 2,
sub
#line 730 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 137
		 'complex_declarator', 1, undef
	],
	[#Rule 138
		 'floating_pt_type', 1,
sub
#line 745 "parser21.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 139
		 'floating_pt_type', 1,
sub
#line 751 "parser21.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 140
		 'floating_pt_type', 2,
sub
#line 757 "parser21.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 141
		 'integer_type', 1, undef
	],
	[#Rule 142
		 'integer_type', 1, undef
	],
	[#Rule 143
		 'signed_int', 1, undef
	],
	[#Rule 144
		 'signed_int', 1, undef
	],
	[#Rule 145
		 'signed_int', 1, undef
	],
	[#Rule 146
		 'signed_short_int', 1,
sub
#line 785 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 147
		 'signed_long_int', 1,
sub
#line 795 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 148
		 'signed_longlong_int', 2,
sub
#line 805 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 149
		 'unsigned_int', 1, undef
	],
	[#Rule 150
		 'unsigned_int', 1, undef
	],
	[#Rule 151
		 'unsigned_int', 1, undef
	],
	[#Rule 152
		 'unsigned_short_int', 2,
sub
#line 825 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 153
		 'unsigned_long_int', 2,
sub
#line 835 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 154
		 'unsigned_longlong_int', 3,
sub
#line 845 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 155
		 'char_type', 1,
sub
#line 855 "parser21.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 156
		 'wide_char_type', 1,
sub
#line 865 "parser21.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 157
		 'boolean_type', 1,
sub
#line 875 "parser21.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 158
		 'octet_type', 1,
sub
#line 885 "parser21.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 159
		 'any_type', 1,
sub
#line 895 "parser21.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 160
		 'object_type', 1,
sub
#line 905 "parser21.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'struct_type', 4,
sub
#line 915 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 162
		 'struct_type', 4,
sub
#line 922 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 163
		 'struct_header', 2,
sub
#line 931 "parser21.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 164
		 'struct_header', 2,
sub
#line 937 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 165
		 'member_list', 1,
sub
#line 946 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 166
		 'member_list', 2,
sub
#line 950 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 167
		 'member', 3,
sub
#line 959 "parser21.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 168
		 'union_type', 8,
sub
#line 970 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 169
		 'union_type', 8,
sub
#line 978 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 170
		 'union_type', 6,
sub
#line 984 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 171
		 'union_type', 5,
sub
#line 990 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 172
		 'union_type', 3,
sub
#line 996 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 173
		 'union_header', 2,
sub
#line 1005 "parser21.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 174
		 'union_header', 2,
sub
#line 1011 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 175
		 'switch_type_spec', 1, undef
	],
	[#Rule 176
		 'switch_type_spec', 1, undef
	],
	[#Rule 177
		 'switch_type_spec', 1, undef
	],
	[#Rule 178
		 'switch_type_spec', 1, undef
	],
	[#Rule 179
		 'switch_type_spec', 1,
sub
#line 1028 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 180
		 'switch_body', 1,
sub
#line 1036 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 181
		 'switch_body', 2,
sub
#line 1040 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 182
		 'case', 3,
sub
#line 1049 "parser21.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 183
		 'case_labels', 1,
sub
#line 1059 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 184
		 'case_labels', 2,
sub
#line 1063 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 185
		 'case_label', 3,
sub
#line 1072 "parser21.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 186
		 'case_label', 3,
sub
#line 1076 "parser21.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 187
		 'case_label', 2,
sub
#line 1082 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 188
		 'case_label', 2,
sub
#line 1087 "parser21.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 189
		 'case_label', 2,
sub
#line 1091 "parser21.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 190
		 'element_spec', 2,
sub
#line 1101 "parser21.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 191
		 'enum_type', 4,
sub
#line 1112 "parser21.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 192
		 'enum_type', 4,
sub
#line 1118 "parser21.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 193
		 'enum_type', 2,
sub
#line 1123 "parser21.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 194
		 'enum_header', 2,
sub
#line 1131 "parser21.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 195
		 'enum_header', 2,
sub
#line 1137 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 196
		 'enumerators', 1,
sub
#line 1145 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 197
		 'enumerators', 3,
sub
#line 1149 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 198
		 'enumerators', 2,
sub
#line 1154 "parser21.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 199
		 'enumerators', 2,
sub
#line 1159 "parser21.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 200
		 'enumerator', 1,
sub
#line 1168 "parser21.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 201
		 'sequence_type', 6,
sub
#line 1178 "parser21.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 202
		 'sequence_type', 6,
sub
#line 1186 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 203
		 'sequence_type', 4,
sub
#line 1191 "parser21.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 204
		 'sequence_type', 4,
sub
#line 1198 "parser21.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 205
		 'sequence_type', 2,
sub
#line 1203 "parser21.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 206
		 'string_type', 4,
sub
#line 1212 "parser21.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 207
		 'string_type', 1,
sub
#line 1219 "parser21.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 208
		 'string_type', 4,
sub
#line 1225 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 209
		 'wide_string_type', 4,
sub
#line 1234 "parser21.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 210
		 'wide_string_type', 1,
sub
#line 1241 "parser21.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 211
		 'wide_string_type', 4,
sub
#line 1247 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 212
		 'array_declarator', 2,
sub
#line 1256 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 213
		 'fixed_array_sizes', 1,
sub
#line 1264 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 214
		 'fixed_array_sizes', 2,
sub
#line 1268 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 215
		 'fixed_array_size', 3,
sub
#line 1277 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 216
		 'fixed_array_size', 3,
sub
#line 1281 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 217
		 'attr_dcl', 4,
sub
#line 1290 "parser21.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 218
		 'attr_dcl', 3,
sub
#line 1298 "parser21.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 219
		 'attr_mod', 1, undef
	],
	[#Rule 220
		 'attr_mod', 0, undef
	],
	[#Rule 221
		 'simple_declarators', 1,
sub
#line 1313 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 222
		 'simple_declarators', 3,
sub
#line 1317 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 223
		 'except_dcl', 3,
sub
#line 1326 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 224
		 'except_dcl', 4,
sub
#line 1331 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 225
		 'except_dcl', 4,
sub
#line 1338 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 226
		 'except_dcl', 2,
sub
#line 1344 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 227
		 'exception_header', 2,
sub
#line 1353 "parser21.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 228
		 'exception_header', 2,
sub
#line 1359 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 229
		 'op_dcl', 4,
sub
#line 1368 "parser21.yp"
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
	[#Rule 230
		 'op_dcl', 2,
sub
#line 1378 "parser21.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 231
		 'op_header', 3,
sub
#line 1388 "parser21.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 232
		 'op_header', 3,
sub
#line 1396 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 233
		 'op_mod', 1, undef
	],
	[#Rule 234
		 'op_mod', 0, undef
	],
	[#Rule 235
		 'op_attribute', 1, undef
	],
	[#Rule 236
		 'op_type_spec', 1, undef
	],
	[#Rule 237
		 'op_type_spec', 1,
sub
#line 1420 "parser21.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 238
		 'op_type_spec', 1,
sub
#line 1426 "parser21.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 239
		 'parameter_dcls', 3,
sub
#line 1435 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 240
		 'parameter_dcls', 5,
sub
#line 1439 "parser21.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 241
		 'parameter_dcls', 4,
sub
#line 1444 "parser21.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 242
		 'parameter_dcls', 2,
sub
#line 1449 "parser21.yp"
{
			undef;
		}
	],
	[#Rule 243
		 'parameter_dcls', 3,
sub
#line 1453 "parser21.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			undef;
		}
	],
	[#Rule 244
		 'parameter_dcls', 3,
sub
#line 1458 "parser21.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 245
		 'param_dcls', 1,
sub
#line 1466 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 246
		 'param_dcls', 3,
sub
#line 1470 "parser21.yp"
{
			push(@{$_[1]},$_[3]);
			$_[1];
		}
	],
	[#Rule 247
		 'param_dcls', 2,
sub
#line 1475 "parser21.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 248
		 'param_dcl', 3,
sub
#line 1484 "parser21.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 249
		 'param_attribute', 1, undef
	],
	[#Rule 250
		 'param_attribute', 1, undef
	],
	[#Rule 251
		 'param_attribute', 1, undef
	],
	[#Rule 252
		 'param_attribute', 0,
sub
#line 1502 "parser21.yp"
{
			$_[0]->Error("(in|out|inout) expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 253
		 'raises_expr', 4,
sub
#line 1511 "parser21.yp"
{
			$_[3];
		}
	],
	[#Rule 254
		 'raises_expr', 4,
sub
#line 1515 "parser21.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 255
		 'raises_expr', 2,
sub
#line 1520 "parser21.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 256
		 'raises_expr', 0, undef
	],
	[#Rule 257
		 'exception_names', 1,
sub
#line 1530 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 258
		 'exception_names', 3,
sub
#line 1534 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 259
		 'exception_name', 1,
sub
#line 1542 "parser21.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 260
		 'context_expr', 4,
sub
#line 1550 "parser21.yp"
{
			$_[3];
		}
	],
	[#Rule 261
		 'context_expr', 4,
sub
#line 1554 "parser21.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 262
		 'context_expr', 2,
sub
#line 1559 "parser21.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 263
		 'context_expr', 0, undef
	],
	[#Rule 264
		 'string_literals', 1,
sub
#line 1569 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 265
		 'string_literals', 3,
sub
#line 1573 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 266
		 'param_type_spec', 1, undef
	],
	[#Rule 267
		 'param_type_spec', 1,
sub
#line 1584 "parser21.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 268
		 'param_type_spec', 1,
sub
#line 1589 "parser21.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 269
		 'param_type_spec', 1,
sub
#line 1594 "parser21.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 270
		 'op_param_type_spec', 1, undef
	],
	[#Rule 271
		 'op_param_type_spec', 1, undef
	],
	[#Rule 272
		 'op_param_type_spec', 1, undef
	],
	[#Rule 273
		 'op_param_type_spec', 1, undef
	],
	[#Rule 274
		 'op_param_type_spec', 1,
sub
#line 1610 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 275
		 'fixed_pt_type', 6,
sub
#line 1618 "parser21.yp"
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
#line 1626 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 277
		 'fixed_pt_type', 4,
sub
#line 1631 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 278
		 'fixed_pt_type', 2,
sub
#line 1636 "parser21.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'fixed_pt_const_type', 1,
sub
#line 1645 "parser21.yp"
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

#line 1652 "parser21.yp"


package Parser;

use strict;
use vars qw($IDL_version);
$IDL_version = '2.1';

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
