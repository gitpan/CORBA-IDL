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
			'MODULE' => 13,
			'UNION' => 15,
			'STRUCT' => 5,
			'error' => 18,
			'CONST' => 21,
			'EXCEPTION' => 22,
			'ENUM' => 27,
			'INTERFACE' => 28
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
			'interface_dcl' => 14,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'module' => 20,
			'enum_header' => 19,
			'union_header' => 23,
			'type_dcl' => 24,
			'definitions' => 25,
			'definition' => 26
		}
	},
	{#State 1
		ACTIONS => {
			'error' => 30,
			";" => 29
		}
	},
	{#State 2
		ACTIONS => {
			"{" => 31
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 33,
			";" => 32
		}
	},
	{#State 4
		ACTIONS => {
			'' => 34
		}
	},
	{#State 5
		ACTIONS => {
			'IDENTIFIER' => 35
		}
	},
	{#State 6
		ACTIONS => {
			"{" => 37,
			'error' => 36
		}
	},
	{#State 7
		ACTIONS => {
			'error' => 39,
			";" => 38
		}
	},
	{#State 8
		DEFAULT => -109
	},
	{#State 9
		ACTIONS => {
			"{" => 41,
			'error' => 40
		}
	},
	{#State 10
		DEFAULT => -110
	},
	{#State 11
		ACTIONS => {
			'CHAR' => 69,
			'OBJECT' => 70,
			'FIXED' => 44,
			'SEQUENCE' => 46,
			'STRUCT' => 5,
			'DOUBLE' => 74,
			'LONG' => 75,
			'STRING' => 76,
			"::" => 77,
			'WSTRING' => 79,
			'UNSIGNED' => 55,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'IDENTIFIER' => 83,
			'UNION' => 15,
			'WCHAR' => 58,
			'error' => 63,
			'FLOAT' => 66,
			'OCTET' => 64,
			'ENUM' => 27,
			'ANY' => 68
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 45,
			'char_type' => 47,
			'object_type' => 48,
			'octet_type' => 49,
			'scoped_name' => 50,
			'wide_char_type' => 51,
			'type_spec' => 53,
			'signed_long_int' => 52,
			'type_declarator' => 54,
			'string_type' => 56,
			'struct_header' => 12,
			'unsigned_longlong_int' => 59,
			'any_type' => 60,
			'base_type_spec' => 61,
			'enum_type' => 62,
			'enum_header' => 19,
			'union_header' => 23,
			'unsigned_short_int' => 65,
			'signed_longlong_int' => 67,
			'wide_string_type' => 71,
			'integer_type' => 72,
			'boolean_type' => 73,
			'signed_short_int' => 78,
			'struct_type' => 80,
			'union_type' => 82,
			'sequence_type' => 84,
			'unsigned_long_int' => 85,
			'template_type_spec' => 86,
			'constr_type_spec' => 87,
			'simple_type_spec' => 88,
			'fixed_pt_type' => 89
		}
	},
	{#State 12
		ACTIONS => {
			"{" => 90
		}
	},
	{#State 13
		ACTIONS => {
			'error' => 91,
			'IDENTIFIER' => 92
		}
	},
	{#State 14
		DEFAULT => -21
	},
	{#State 15
		ACTIONS => {
			'IDENTIFIER' => 93
		}
	},
	{#State 16
		DEFAULT => -111
	},
	{#State 17
		DEFAULT => -22
	},
	{#State 18
		DEFAULT => -3
	},
	{#State 19
		ACTIONS => {
			"{" => 95,
			'error' => 94
		}
	},
	{#State 20
		ACTIONS => {
			'error' => 97,
			";" => 96
		}
	},
	{#State 21
		ACTIONS => {
			'CHAR' => 69,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'IDENTIFIER' => 83,
			'FIXED' => 99,
			'WCHAR' => 58,
			'DOUBLE' => 74,
			'error' => 104,
			'LONG' => 75,
			'STRING' => 76,
			"::" => 77,
			'FLOAT' => 66,
			'WSTRING' => 79,
			'UNSIGNED' => 55
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 98,
			'signed_int' => 45,
			'wide_string_type' => 105,
			'integer_type' => 107,
			'boolean_type' => 106,
			'char_type' => 100,
			'scoped_name' => 101,
			'fixed_pt_const_type' => 108,
			'wide_char_type' => 102,
			'signed_long_int' => 52,
			'signed_short_int' => 78,
			'const_type' => 109,
			'string_type' => 103,
			'unsigned_longlong_int' => 59,
			'unsigned_long_int' => 85,
			'unsigned_short_int' => 65,
			'signed_longlong_int' => 67
		}
	},
	{#State 22
		ACTIONS => {
			'error' => 110,
			'IDENTIFIER' => 111
		}
	},
	{#State 23
		ACTIONS => {
			'SWITCH' => 112
		}
	},
	{#State 24
		ACTIONS => {
			'error' => 114,
			";" => 113
		}
	},
	{#State 25
		DEFAULT => -1
	},
	{#State 26
		ACTIONS => {
			'TYPEDEF' => 11,
			'MODULE' => 13,
			'UNION' => 15,
			'STRUCT' => 5,
			'CONST' => 21,
			'EXCEPTION' => 22,
			'ENUM' => 27,
			'INTERFACE' => 28
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
			'interface_dcl' => 14,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'enum_header' => 19,
			'module' => 20,
			'union_header' => 23,
			'definitions' => 115,
			'type_dcl' => 24,
			'definition' => 26
		}
	},
	{#State 27
		ACTIONS => {
			'error' => 116,
			'IDENTIFIER' => 117
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 118,
			'IDENTIFIER' => 119
		}
	},
	{#State 29
		DEFAULT => -7
	},
	{#State 30
		DEFAULT => -12
	},
	{#State 31
		ACTIONS => {
			'CHAR' => -241,
			'OBJECT' => -241,
			'ONEWAY' => 120,
			'FIXED' => -241,
			'VOID' => -241,
			'STRUCT' => 5,
			'DOUBLE' => -241,
			'LONG' => -241,
			'STRING' => -241,
			"::" => -241,
			'WSTRING' => -241,
			'UNSIGNED' => -241,
			'SHORT' => -241,
			'TYPEDEF' => 11,
			'BOOLEAN' => -241,
			'IDENTIFIER' => -241,
			'UNION' => 15,
			'READONLY' => 131,
			'WCHAR' => -241,
			'ATTRIBUTE' => -224,
			'error' => 125,
			'CONST' => 21,
			"}" => 126,
			'EXCEPTION' => 22,
			'OCTET' => -241,
			'FLOAT' => -241,
			'ENUM' => 27,
			'ANY' => -241
		},
		GOTOS => {
			'const_dcl' => 127,
			'op_mod' => 121,
			'except_dcl' => 122,
			'op_attribute' => 123,
			'attr_mod' => 124,
			'exports' => 128,
			'export' => 129,
			'struct_type' => 8,
			'op_header' => 130,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 16,
			'op_dcl' => 132,
			'enum_header' => 19,
			'attr_dcl' => 133,
			'type_dcl' => 134,
			'union_header' => 23,
			'interface_body' => 135
		}
	},
	{#State 32
		DEFAULT => -8
	},
	{#State 33
		DEFAULT => -13
	},
	{#State 34
		DEFAULT => 0
	},
	{#State 35
		DEFAULT => -166
	},
	{#State 36
		DEFAULT => -18
	},
	{#State 37
		ACTIONS => {
			'TYPEDEF' => 11,
			'MODULE' => 13,
			'UNION' => 15,
			'STRUCT' => 5,
			'error' => 136,
			'CONST' => 21,
			'EXCEPTION' => 22,
			'ENUM' => 27,
			'INTERFACE' => 28
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
			'interface_dcl' => 14,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'enum_header' => 19,
			'module' => 20,
			'union_header' => 23,
			'definitions' => 137,
			'type_dcl' => 24,
			'definition' => 26
		}
	},
	{#State 38
		DEFAULT => -9
	},
	{#State 39
		DEFAULT => -14
	},
	{#State 40
		DEFAULT => -230
	},
	{#State 41
		ACTIONS => {
			'CHAR' => 69,
			'OBJECT' => 70,
			'FIXED' => 44,
			'SEQUENCE' => 46,
			'STRUCT' => 5,
			'DOUBLE' => 74,
			'LONG' => 75,
			'STRING' => 76,
			"::" => 77,
			'WSTRING' => 79,
			'UNSIGNED' => 55,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'IDENTIFIER' => 83,
			'UNION' => 15,
			'WCHAR' => 58,
			'error' => 139,
			"}" => 141,
			'FLOAT' => 66,
			'OCTET' => 64,
			'ENUM' => 27,
			'ANY' => 68
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 45,
			'char_type' => 47,
			'object_type' => 48,
			'octet_type' => 49,
			'scoped_name' => 50,
			'wide_char_type' => 51,
			'signed_long_int' => 52,
			'type_spec' => 138,
			'string_type' => 56,
			'struct_header' => 12,
			'unsigned_longlong_int' => 59,
			'any_type' => 60,
			'base_type_spec' => 61,
			'enum_type' => 62,
			'enum_header' => 19,
			'member_list' => 140,
			'union_header' => 23,
			'unsigned_short_int' => 65,
			'signed_longlong_int' => 67,
			'wide_string_type' => 71,
			'boolean_type' => 73,
			'integer_type' => 72,
			'signed_short_int' => 78,
			'member' => 142,
			'struct_type' => 80,
			'union_type' => 82,
			'sequence_type' => 84,
			'unsigned_long_int' => 85,
			'template_type_spec' => 86,
			'constr_type_spec' => 87,
			'simple_type_spec' => 88,
			'fixed_pt_type' => 89
		}
	},
	{#State 42
		DEFAULT => -145
	},
	{#State 43
		DEFAULT => -120
	},
	{#State 44
		ACTIONS => {
			"<" => 144,
			'error' => 143
		}
	},
	{#State 45
		DEFAULT => -144
	},
	{#State 46
		ACTIONS => {
			"<" => 146,
			'error' => 145
		}
	},
	{#State 47
		DEFAULT => -122
	},
	{#State 48
		DEFAULT => -127
	},
	{#State 49
		DEFAULT => -125
	},
	{#State 50
		ACTIONS => {
			"::" => 147
		},
		DEFAULT => -119
	},
	{#State 51
		DEFAULT => -123
	},
	{#State 52
		DEFAULT => -147
	},
	{#State 53
		ACTIONS => {
			'error' => 150,
			'IDENTIFIER' => 154
		},
		GOTOS => {
			'declarators' => 148,
			'declarator' => 149,
			'simple_declarator' => 152,
			'array_declarator' => 153,
			'complex_declarator' => 151
		}
	},
	{#State 54
		DEFAULT => -108
	},
	{#State 55
		ACTIONS => {
			'SHORT' => 155,
			'LONG' => 156
		}
	},
	{#State 56
		DEFAULT => -129
	},
	{#State 57
		DEFAULT => -149
	},
	{#State 58
		DEFAULT => -159
	},
	{#State 59
		DEFAULT => -154
	},
	{#State 60
		DEFAULT => -126
	},
	{#State 61
		DEFAULT => -117
	},
	{#State 62
		DEFAULT => -134
	},
	{#State 63
		DEFAULT => -112
	},
	{#State 64
		DEFAULT => -161
	},
	{#State 65
		DEFAULT => -152
	},
	{#State 66
		DEFAULT => -141
	},
	{#State 67
		DEFAULT => -148
	},
	{#State 68
		DEFAULT => -162
	},
	{#State 69
		DEFAULT => -158
	},
	{#State 70
		DEFAULT => -163
	},
	{#State 71
		DEFAULT => -130
	},
	{#State 72
		DEFAULT => -121
	},
	{#State 73
		DEFAULT => -124
	},
	{#State 74
		DEFAULT => -142
	},
	{#State 75
		ACTIONS => {
			'LONG' => 158,
			'DOUBLE' => 157
		},
		DEFAULT => -150
	},
	{#State 76
		ACTIONS => {
			"<" => 159
		},
		DEFAULT => -210
	},
	{#State 77
		ACTIONS => {
			'error' => 160,
			'IDENTIFIER' => 161
		}
	},
	{#State 78
		DEFAULT => -146
	},
	{#State 79
		ACTIONS => {
			"<" => 162
		},
		DEFAULT => -213
	},
	{#State 80
		DEFAULT => -132
	},
	{#State 81
		DEFAULT => -160
	},
	{#State 82
		DEFAULT => -133
	},
	{#State 83
		DEFAULT => -48
	},
	{#State 84
		DEFAULT => -128
	},
	{#State 85
		DEFAULT => -153
	},
	{#State 86
		DEFAULT => -118
	},
	{#State 87
		DEFAULT => -116
	},
	{#State 88
		DEFAULT => -115
	},
	{#State 89
		DEFAULT => -131
	},
	{#State 90
		ACTIONS => {
			'CHAR' => 69,
			'OBJECT' => 70,
			'FIXED' => 44,
			'SEQUENCE' => 46,
			'STRUCT' => 5,
			'DOUBLE' => 74,
			'LONG' => 75,
			'STRING' => 76,
			"::" => 77,
			'WSTRING' => 79,
			'UNSIGNED' => 55,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'IDENTIFIER' => 83,
			'UNION' => 15,
			'WCHAR' => 58,
			'error' => 163,
			'FLOAT' => 66,
			'OCTET' => 64,
			'ENUM' => 27,
			'ANY' => 68
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 45,
			'char_type' => 47,
			'object_type' => 48,
			'octet_type' => 49,
			'scoped_name' => 50,
			'wide_char_type' => 51,
			'signed_long_int' => 52,
			'type_spec' => 138,
			'string_type' => 56,
			'struct_header' => 12,
			'unsigned_longlong_int' => 59,
			'any_type' => 60,
			'base_type_spec' => 61,
			'enum_type' => 62,
			'enum_header' => 19,
			'member_list' => 164,
			'union_header' => 23,
			'unsigned_short_int' => 65,
			'signed_longlong_int' => 67,
			'wide_string_type' => 71,
			'boolean_type' => 73,
			'integer_type' => 72,
			'signed_short_int' => 78,
			'member' => 142,
			'struct_type' => 80,
			'union_type' => 82,
			'sequence_type' => 84,
			'unsigned_long_int' => 85,
			'template_type_spec' => 86,
			'constr_type_spec' => 87,
			'simple_type_spec' => 88,
			'fixed_pt_type' => 89
		}
	},
	{#State 91
		DEFAULT => -20
	},
	{#State 92
		DEFAULT => -19
	},
	{#State 93
		DEFAULT => -176
	},
	{#State 94
		DEFAULT => -196
	},
	{#State 95
		ACTIONS => {
			'error' => 165,
			'IDENTIFIER' => 167
		},
		GOTOS => {
			'enumerators' => 168,
			'enumerator' => 166
		}
	},
	{#State 96
		DEFAULT => -10
	},
	{#State 97
		DEFAULT => -15
	},
	{#State 98
		DEFAULT => -62
	},
	{#State 99
		DEFAULT => -276
	},
	{#State 100
		DEFAULT => -59
	},
	{#State 101
		ACTIONS => {
			"::" => 147
		},
		DEFAULT => -66
	},
	{#State 102
		DEFAULT => -60
	},
	{#State 103
		DEFAULT => -63
	},
	{#State 104
		DEFAULT => -57
	},
	{#State 105
		DEFAULT => -64
	},
	{#State 106
		DEFAULT => -61
	},
	{#State 107
		DEFAULT => -58
	},
	{#State 108
		DEFAULT => -65
	},
	{#State 109
		ACTIONS => {
			'error' => 169,
			'IDENTIFIER' => 170
		}
	},
	{#State 110
		DEFAULT => -232
	},
	{#State 111
		DEFAULT => -231
	},
	{#State 112
		ACTIONS => {
			'error' => 172,
			"(" => 171
		}
	},
	{#State 113
		DEFAULT => -6
	},
	{#State 114
		DEFAULT => -11
	},
	{#State 115
		DEFAULT => -5
	},
	{#State 116
		DEFAULT => -198
	},
	{#State 117
		DEFAULT => -197
	},
	{#State 118
		DEFAULT => -27
	},
	{#State 119
		ACTIONS => {
			"{" => -28,
			":" => 173
		},
		DEFAULT => -26,
		GOTOS => {
			'interface_inheritance_spec' => 174
		}
	},
	{#State 120
		DEFAULT => -242
	},
	{#State 121
		ACTIONS => {
			'CHAR' => 69,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'OBJECT' => 70,
			'IDENTIFIER' => 83,
			'FIXED' => 44,
			'VOID' => 180,
			'WCHAR' => 58,
			'DOUBLE' => 74,
			'LONG' => 75,
			'STRING' => 76,
			"::" => 77,
			'OCTET' => 64,
			'FLOAT' => 66,
			'WSTRING' => 79,
			'UNSIGNED' => 55,
			'ANY' => 68
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 45,
			'wide_string_type' => 179,
			'integer_type' => 72,
			'boolean_type' => 73,
			'char_type' => 47,
			'object_type' => 48,
			'octet_type' => 49,
			'scoped_name' => 175,
			'wide_char_type' => 51,
			'signed_long_int' => 52,
			'signed_short_int' => 78,
			'string_type' => 176,
			'op_type_spec' => 181,
			'base_type_spec' => 177,
			'unsigned_longlong_int' => 59,
			'any_type' => 60,
			'unsigned_long_int' => 85,
			'param_type_spec' => 178,
			'unsigned_short_int' => 65,
			'fixed_pt_type' => 182,
			'signed_longlong_int' => 67
		}
	},
	{#State 122
		ACTIONS => {
			'error' => 184,
			";" => 183
		}
	},
	{#State 123
		DEFAULT => -240
	},
	{#State 124
		ACTIONS => {
			'ATTRIBUTE' => 185
		}
	},
	{#State 125
		ACTIONS => {
			"}" => 186
		}
	},
	{#State 126
		DEFAULT => -23
	},
	{#State 127
		ACTIONS => {
			'error' => 188,
			";" => 187
		}
	},
	{#State 128
		DEFAULT => -30
	},
	{#State 129
		ACTIONS => {
			'ONEWAY' => 120,
			'STRUCT' => 5,
			'TYPEDEF' => 11,
			'UNION' => 15,
			'READONLY' => 131,
			'ATTRIBUTE' => -224,
			'CONST' => 21,
			"}" => -31,
			'EXCEPTION' => 22,
			'ENUM' => 27
		},
		DEFAULT => -241,
		GOTOS => {
			'const_dcl' => 127,
			'op_mod' => 121,
			'except_dcl' => 122,
			'op_attribute' => 123,
			'attr_mod' => 124,
			'exports' => 189,
			'export' => 129,
			'struct_type' => 8,
			'op_header' => 130,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 16,
			'op_dcl' => 132,
			'enum_header' => 19,
			'attr_dcl' => 133,
			'type_dcl' => 134,
			'union_header' => 23
		}
	},
	{#State 130
		ACTIONS => {
			'error' => 191,
			"(" => 190
		},
		GOTOS => {
			'parameter_dcls' => 192
		}
	},
	{#State 131
		DEFAULT => -223
	},
	{#State 132
		ACTIONS => {
			'error' => 194,
			";" => 193
		}
	},
	{#State 133
		ACTIONS => {
			'error' => 196,
			";" => 195
		}
	},
	{#State 134
		ACTIONS => {
			'error' => 198,
			";" => 197
		}
	},
	{#State 135
		ACTIONS => {
			"}" => 199
		}
	},
	{#State 136
		ACTIONS => {
			"}" => 200
		}
	},
	{#State 137
		ACTIONS => {
			"}" => 201
		}
	},
	{#State 138
		ACTIONS => {
			'IDENTIFIER' => 154
		},
		GOTOS => {
			'declarators' => 202,
			'declarator' => 149,
			'simple_declarator' => 152,
			'array_declarator' => 153,
			'complex_declarator' => 151
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
		DEFAULT => -227
	},
	{#State 142
		ACTIONS => {
			'CHAR' => 69,
			'OBJECT' => 70,
			'FIXED' => 44,
			'SEQUENCE' => 46,
			'STRUCT' => 5,
			'DOUBLE' => 74,
			'LONG' => 75,
			'STRING' => 76,
			"::" => 77,
			'WSTRING' => 79,
			'UNSIGNED' => 55,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'IDENTIFIER' => 83,
			'UNION' => 15,
			'WCHAR' => 58,
			'FLOAT' => 66,
			'OCTET' => 64,
			'ENUM' => 27,
			'ANY' => 68
		},
		DEFAULT => -167,
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 45,
			'char_type' => 47,
			'object_type' => 48,
			'octet_type' => 49,
			'scoped_name' => 50,
			'wide_char_type' => 51,
			'signed_long_int' => 52,
			'type_spec' => 138,
			'string_type' => 56,
			'struct_header' => 12,
			'unsigned_longlong_int' => 59,
			'any_type' => 60,
			'base_type_spec' => 61,
			'enum_type' => 62,
			'enum_header' => 19,
			'member_list' => 205,
			'union_header' => 23,
			'unsigned_short_int' => 65,
			'signed_longlong_int' => 67,
			'wide_string_type' => 71,
			'boolean_type' => 73,
			'integer_type' => 72,
			'signed_short_int' => 78,
			'member' => 142,
			'struct_type' => 80,
			'union_type' => 82,
			'sequence_type' => 84,
			'unsigned_long_int' => 85,
			'template_type_spec' => 86,
			'constr_type_spec' => 87,
			'simple_type_spec' => 88,
			'fixed_pt_type' => 89
		}
	},
	{#State 143
		DEFAULT => -275
	},
	{#State 144
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'CHARACTER_LITERAL' => 206,
			'WIDE_CHARACTER_LITERAL' => 207,
			"::" => 77,
			'INTEGER_LITERAL' => 227,
			"(" => 211,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'FIXED_PT_LITERAL' => 230,
			"+" => 231,
			'error' => 215,
			"-" => 233,
			'WIDE_STRING_LITERAL' => 219,
			'FALSE' => 218,
			"~" => 234,
			'TRUE' => 221
		},
		GOTOS => {
			'string_literal' => 223,
			'primary_expr' => 225,
			'and_expr' => 226,
			'scoped_name' => 208,
			'positive_int_const' => 209,
			'wide_string_literal' => 210,
			'boolean_literal' => 212,
			'mult_expr' => 228,
			'const_exp' => 213,
			'or_expr' => 214,
			'unary_expr' => 232,
			'xor_expr' => 216,
			'shift_expr' => 217,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 145
		DEFAULT => -208
	},
	{#State 146
		ACTIONS => {
			'CHAR' => 69,
			'OBJECT' => 70,
			'FIXED' => 44,
			'SEQUENCE' => 46,
			'DOUBLE' => 74,
			'LONG' => 75,
			'STRING' => 76,
			"::" => 77,
			'WSTRING' => 79,
			'UNSIGNED' => 55,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'IDENTIFIER' => 83,
			'WCHAR' => 58,
			'error' => 236,
			'FLOAT' => 66,
			'OCTET' => 64,
			'ANY' => 68
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 45,
			'wide_string_type' => 71,
			'integer_type' => 72,
			'boolean_type' => 73,
			'char_type' => 47,
			'object_type' => 48,
			'octet_type' => 49,
			'scoped_name' => 50,
			'wide_char_type' => 51,
			'signed_long_int' => 52,
			'signed_short_int' => 78,
			'string_type' => 56,
			'sequence_type' => 84,
			'unsigned_longlong_int' => 59,
			'any_type' => 60,
			'base_type_spec' => 61,
			'unsigned_long_int' => 85,
			'template_type_spec' => 86,
			'unsigned_short_int' => 65,
			'simple_type_spec' => 237,
			'fixed_pt_type' => 89,
			'signed_longlong_int' => 67
		}
	},
	{#State 147
		ACTIONS => {
			'error' => 238,
			'IDENTIFIER' => 239
		}
	},
	{#State 148
		DEFAULT => -113
	},
	{#State 149
		ACTIONS => {
			"," => 240
		},
		DEFAULT => -135
	},
	{#State 150
		DEFAULT => -114
	},
	{#State 151
		DEFAULT => -138
	},
	{#State 152
		DEFAULT => -137
	},
	{#State 153
		DEFAULT => -140
	},
	{#State 154
		ACTIONS => {
			"[" => 243
		},
		DEFAULT => -139,
		GOTOS => {
			'fixed_array_sizes' => 241,
			'fixed_array_size' => 242
		}
	},
	{#State 155
		DEFAULT => -155
	},
	{#State 156
		ACTIONS => {
			'LONG' => 244
		},
		DEFAULT => -156
	},
	{#State 157
		DEFAULT => -143
	},
	{#State 158
		DEFAULT => -151
	},
	{#State 159
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'CHARACTER_LITERAL' => 206,
			'WIDE_CHARACTER_LITERAL' => 207,
			"::" => 77,
			'INTEGER_LITERAL' => 227,
			"(" => 211,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'FIXED_PT_LITERAL' => 230,
			"+" => 231,
			'error' => 246,
			"-" => 233,
			'WIDE_STRING_LITERAL' => 219,
			'FALSE' => 218,
			"~" => 234,
			'TRUE' => 221
		},
		GOTOS => {
			'string_literal' => 223,
			'primary_expr' => 225,
			'and_expr' => 226,
			'scoped_name' => 208,
			'positive_int_const' => 245,
			'wide_string_literal' => 210,
			'boolean_literal' => 212,
			'mult_expr' => 228,
			'const_exp' => 213,
			'or_expr' => 214,
			'unary_expr' => 232,
			'xor_expr' => 216,
			'shift_expr' => 217,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 160
		DEFAULT => -50
	},
	{#State 161
		DEFAULT => -49
	},
	{#State 162
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'CHARACTER_LITERAL' => 206,
			'WIDE_CHARACTER_LITERAL' => 207,
			"::" => 77,
			'INTEGER_LITERAL' => 227,
			"(" => 211,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'FIXED_PT_LITERAL' => 230,
			"+" => 231,
			'error' => 248,
			"-" => 233,
			'WIDE_STRING_LITERAL' => 219,
			'FALSE' => 218,
			"~" => 234,
			'TRUE' => 221
		},
		GOTOS => {
			'string_literal' => 223,
			'primary_expr' => 225,
			'and_expr' => 226,
			'scoped_name' => 208,
			'positive_int_const' => 247,
			'wide_string_literal' => 210,
			'boolean_literal' => 212,
			'mult_expr' => 228,
			'const_exp' => 213,
			'or_expr' => 214,
			'unary_expr' => 232,
			'xor_expr' => 216,
			'shift_expr' => 217,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 163
		ACTIONS => {
			"}" => 249
		}
	},
	{#State 164
		ACTIONS => {
			"}" => 250
		}
	},
	{#State 165
		ACTIONS => {
			"}" => 251
		}
	},
	{#State 166
		ACTIONS => {
			";" => 252,
			"," => 253
		},
		DEFAULT => -199
	},
	{#State 167
		DEFAULT => -203
	},
	{#State 168
		ACTIONS => {
			"}" => 254
		}
	},
	{#State 169
		DEFAULT => -56
	},
	{#State 170
		ACTIONS => {
			'error' => 255,
			"=" => 256
		}
	},
	{#State 171
		ACTIONS => {
			'CHAR' => 69,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'IDENTIFIER' => 83,
			'error' => 260,
			'LONG' => 264,
			"::" => 77,
			'ENUM' => 27,
			'UNSIGNED' => 55
		},
		GOTOS => {
			'switch_type_spec' => 261,
			'unsigned_int' => 42,
			'signed_int' => 45,
			'integer_type' => 263,
			'boolean_type' => 262,
			'unsigned_longlong_int' => 59,
			'char_type' => 257,
			'enum_type' => 259,
			'unsigned_long_int' => 85,
			'scoped_name' => 258,
			'enum_header' => 19,
			'signed_long_int' => 52,
			'unsigned_short_int' => 65,
			'signed_short_int' => 78,
			'signed_longlong_int' => 67
		}
	},
	{#State 172
		DEFAULT => -175
	},
	{#State 173
		ACTIONS => {
			'error' => 266,
			'IDENTIFIER' => 83,
			"::" => 77
		},
		GOTOS => {
			'scoped_name' => 265,
			'interface_names' => 268,
			'interface_name' => 267
		}
	},
	{#State 174
		DEFAULT => -29
	},
	{#State 175
		ACTIONS => {
			"::" => 147
		},
		DEFAULT => -271
	},
	{#State 176
		DEFAULT => -268
	},
	{#State 177
		DEFAULT => -267
	},
	{#State 178
		DEFAULT => -243
	},
	{#State 179
		DEFAULT => -269
	},
	{#State 180
		DEFAULT => -244
	},
	{#State 181
		ACTIONS => {
			'error' => 269,
			'IDENTIFIER' => 270
		}
	},
	{#State 182
		DEFAULT => -270
	},
	{#State 183
		DEFAULT => -35
	},
	{#State 184
		DEFAULT => -40
	},
	{#State 185
		ACTIONS => {
			'CHAR' => 69,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'OBJECT' => 70,
			'IDENTIFIER' => 83,
			'FIXED' => 44,
			'WCHAR' => 58,
			'DOUBLE' => 74,
			'error' => 271,
			'LONG' => 75,
			'STRING' => 76,
			"::" => 77,
			'OCTET' => 64,
			'FLOAT' => 66,
			'WSTRING' => 79,
			'UNSIGNED' => 55,
			'ANY' => 68
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 45,
			'wide_string_type' => 179,
			'integer_type' => 72,
			'boolean_type' => 73,
			'char_type' => 47,
			'object_type' => 48,
			'octet_type' => 49,
			'scoped_name' => 175,
			'wide_char_type' => 51,
			'signed_long_int' => 52,
			'signed_short_int' => 78,
			'string_type' => 176,
			'base_type_spec' => 177,
			'unsigned_longlong_int' => 59,
			'any_type' => 60,
			'unsigned_long_int' => 85,
			'param_type_spec' => 272,
			'unsigned_short_int' => 65,
			'fixed_pt_type' => 182,
			'signed_longlong_int' => 67
		}
	},
	{#State 186
		DEFAULT => -25
	},
	{#State 187
		DEFAULT => -34
	},
	{#State 188
		DEFAULT => -39
	},
	{#State 189
		DEFAULT => -32
	},
	{#State 190
		ACTIONS => {
			'error' => 274,
			")" => 278,
			'OUT' => 279,
			'INOUT' => 275,
			'IN' => 273
		},
		GOTOS => {
			'param_dcl' => 280,
			'param_dcls' => 277,
			'param_attribute' => 276
		}
	},
	{#State 191
		DEFAULT => -237
	},
	{#State 192
		ACTIONS => {
			'RAISES' => 284,
			'CONTEXT' => 281
		},
		DEFAULT => -233,
		GOTOS => {
			'context_expr' => 283,
			'raises_expr' => 282
		}
	},
	{#State 193
		DEFAULT => -37
	},
	{#State 194
		DEFAULT => -42
	},
	{#State 195
		DEFAULT => -36
	},
	{#State 196
		DEFAULT => -41
	},
	{#State 197
		DEFAULT => -33
	},
	{#State 198
		DEFAULT => -38
	},
	{#State 199
		DEFAULT => -24
	},
	{#State 200
		DEFAULT => -17
	},
	{#State 201
		DEFAULT => -16
	},
	{#State 202
		ACTIONS => {
			'error' => 286,
			";" => 285
		}
	},
	{#State 203
		DEFAULT => -229
	},
	{#State 204
		DEFAULT => -228
	},
	{#State 205
		DEFAULT => -168
	},
	{#State 206
		DEFAULT => -96
	},
	{#State 207
		DEFAULT => -97
	},
	{#State 208
		ACTIONS => {
			"::" => 147
		},
		DEFAULT => -89
	},
	{#State 209
		ACTIONS => {
			"," => 287
		}
	},
	{#State 210
		DEFAULT => -95
	},
	{#State 211
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'CHARACTER_LITERAL' => 206,
			'WIDE_CHARACTER_LITERAL' => 207,
			"::" => 77,
			'INTEGER_LITERAL' => 227,
			"(" => 211,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'FIXED_PT_LITERAL' => 230,
			"+" => 231,
			'error' => 289,
			"-" => 233,
			'WIDE_STRING_LITERAL' => 219,
			'FALSE' => 218,
			"~" => 234,
			'TRUE' => 221
		},
		GOTOS => {
			'mult_expr' => 228,
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'const_exp' => 288,
			'and_expr' => 226,
			'or_expr' => 214,
			'unary_expr' => 232,
			'scoped_name' => 208,
			'xor_expr' => 216,
			'shift_expr' => 217,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 212
		DEFAULT => -100
	},
	{#State 213
		DEFAULT => -107
	},
	{#State 214
		ACTIONS => {
			"|" => 290
		},
		DEFAULT => -67
	},
	{#State 215
		ACTIONS => {
			">" => 291
		}
	},
	{#State 216
		ACTIONS => {
			"^" => 292
		},
		DEFAULT => -68
	},
	{#State 217
		ACTIONS => {
			"<<" => 293,
			">>" => 294
		},
		DEFAULT => -72
	},
	{#State 218
		DEFAULT => -106
	},
	{#State 219
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 219
		},
		DEFAULT => -103,
		GOTOS => {
			'wide_string_literal' => 295
		}
	},
	{#State 220
		DEFAULT => -90
	},
	{#State 221
		DEFAULT => -105
	},
	{#State 222
		ACTIONS => {
			"+" => 296,
			"-" => 297
		},
		DEFAULT => -74
	},
	{#State 223
		DEFAULT => -94
	},
	{#State 224
		DEFAULT => -99
	},
	{#State 225
		DEFAULT => -85
	},
	{#State 226
		ACTIONS => {
			"&" => 298
		},
		DEFAULT => -70
	},
	{#State 227
		DEFAULT => -93
	},
	{#State 228
		ACTIONS => {
			"%" => 300,
			"*" => 299,
			"/" => 301
		},
		DEFAULT => -77
	},
	{#State 229
		ACTIONS => {
			'STRING_LITERAL' => 229
		},
		DEFAULT => -101,
		GOTOS => {
			'string_literal' => 302
		}
	},
	{#State 230
		DEFAULT => -98
	},
	{#State 231
		DEFAULT => -87
	},
	{#State 232
		DEFAULT => -80
	},
	{#State 233
		DEFAULT => -86
	},
	{#State 234
		DEFAULT => -88
	},
	{#State 235
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'string_literal' => 223,
			'boolean_literal' => 212,
			'scoped_name' => 208,
			'primary_expr' => 303,
			'literal' => 220,
			'wide_string_literal' => 210
		}
	},
	{#State 236
		ACTIONS => {
			">" => 304
		}
	},
	{#State 237
		ACTIONS => {
			">" => 306,
			"," => 305
		}
	},
	{#State 238
		DEFAULT => -52
	},
	{#State 239
		DEFAULT => -51
	},
	{#State 240
		ACTIONS => {
			'IDENTIFIER' => 154
		},
		GOTOS => {
			'declarators' => 307,
			'declarator' => 149,
			'simple_declarator' => 152,
			'array_declarator' => 153,
			'complex_declarator' => 151
		}
	},
	{#State 241
		DEFAULT => -215
	},
	{#State 242
		ACTIONS => {
			"[" => 243
		},
		DEFAULT => -216,
		GOTOS => {
			'fixed_array_sizes' => 308,
			'fixed_array_size' => 242
		}
	},
	{#State 243
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'CHARACTER_LITERAL' => 206,
			'WIDE_CHARACTER_LITERAL' => 207,
			"::" => 77,
			'INTEGER_LITERAL' => 227,
			"(" => 211,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'FIXED_PT_LITERAL' => 230,
			"+" => 231,
			'error' => 310,
			"-" => 233,
			'WIDE_STRING_LITERAL' => 219,
			'FALSE' => 218,
			"~" => 234,
			'TRUE' => 221
		},
		GOTOS => {
			'string_literal' => 223,
			'primary_expr' => 225,
			'and_expr' => 226,
			'scoped_name' => 208,
			'positive_int_const' => 309,
			'wide_string_literal' => 210,
			'boolean_literal' => 212,
			'mult_expr' => 228,
			'const_exp' => 213,
			'or_expr' => 214,
			'unary_expr' => 232,
			'xor_expr' => 216,
			'shift_expr' => 217,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 244
		DEFAULT => -157
	},
	{#State 245
		ACTIONS => {
			">" => 311
		}
	},
	{#State 246
		ACTIONS => {
			">" => 312
		}
	},
	{#State 247
		ACTIONS => {
			">" => 313
		}
	},
	{#State 248
		ACTIONS => {
			">" => 314
		}
	},
	{#State 249
		DEFAULT => -165
	},
	{#State 250
		DEFAULT => -164
	},
	{#State 251
		DEFAULT => -195
	},
	{#State 252
		DEFAULT => -202
	},
	{#State 253
		ACTIONS => {
			'IDENTIFIER' => 167
		},
		DEFAULT => -201,
		GOTOS => {
			'enumerators' => 315,
			'enumerator' => 166
		}
	},
	{#State 254
		DEFAULT => -194
	},
	{#State 255
		DEFAULT => -55
	},
	{#State 256
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'CHARACTER_LITERAL' => 206,
			'WIDE_CHARACTER_LITERAL' => 207,
			"::" => 77,
			'INTEGER_LITERAL' => 227,
			"(" => 211,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'FIXED_PT_LITERAL' => 230,
			"+" => 231,
			'error' => 317,
			"-" => 233,
			'WIDE_STRING_LITERAL' => 219,
			'FALSE' => 218,
			"~" => 234,
			'TRUE' => 221
		},
		GOTOS => {
			'mult_expr' => 228,
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'const_exp' => 316,
			'and_expr' => 226,
			'or_expr' => 214,
			'unary_expr' => 232,
			'scoped_name' => 208,
			'xor_expr' => 216,
			'shift_expr' => 217,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 257
		DEFAULT => -178
	},
	{#State 258
		ACTIONS => {
			"::" => 147
		},
		DEFAULT => -181
	},
	{#State 259
		DEFAULT => -180
	},
	{#State 260
		ACTIONS => {
			")" => 318
		}
	},
	{#State 261
		ACTIONS => {
			")" => 319
		}
	},
	{#State 262
		DEFAULT => -179
	},
	{#State 263
		DEFAULT => -177
	},
	{#State 264
		ACTIONS => {
			'LONG' => 158
		},
		DEFAULT => -150
	},
	{#State 265
		ACTIONS => {
			"::" => 147
		},
		DEFAULT => -47
	},
	{#State 266
		DEFAULT => -44
	},
	{#State 267
		ACTIONS => {
			"," => 320
		},
		DEFAULT => -45
	},
	{#State 268
		DEFAULT => -43
	},
	{#State 269
		DEFAULT => -239
	},
	{#State 270
		DEFAULT => -238
	},
	{#State 271
		DEFAULT => -222
	},
	{#State 272
		ACTIONS => {
			'error' => 321,
			'IDENTIFIER' => 324
		},
		GOTOS => {
			'simple_declarators' => 323,
			'simple_declarator' => 322
		}
	},
	{#State 273
		DEFAULT => -253
	},
	{#State 274
		ACTIONS => {
			")" => 325
		}
	},
	{#State 275
		DEFAULT => -255
	},
	{#State 276
		ACTIONS => {
			'CHAR' => 69,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'OBJECT' => 70,
			'IDENTIFIER' => 83,
			'FIXED' => 44,
			'WCHAR' => 58,
			'DOUBLE' => 74,
			'LONG' => 75,
			'STRING' => 76,
			"::" => 77,
			'OCTET' => 64,
			'FLOAT' => 66,
			'WSTRING' => 79,
			'UNSIGNED' => 55,
			'ANY' => 68
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 45,
			'wide_string_type' => 179,
			'integer_type' => 72,
			'boolean_type' => 73,
			'char_type' => 47,
			'object_type' => 48,
			'octet_type' => 49,
			'scoped_name' => 175,
			'wide_char_type' => 51,
			'signed_long_int' => 52,
			'signed_short_int' => 78,
			'string_type' => 176,
			'base_type_spec' => 177,
			'unsigned_longlong_int' => 59,
			'any_type' => 60,
			'unsigned_long_int' => 85,
			'param_type_spec' => 326,
			'unsigned_short_int' => 65,
			'fixed_pt_type' => 182,
			'signed_longlong_int' => 67
		}
	},
	{#State 277
		ACTIONS => {
			")" => 327
		}
	},
	{#State 278
		DEFAULT => -246
	},
	{#State 279
		DEFAULT => -254
	},
	{#State 280
		ACTIONS => {
			";" => 328,
			"," => 329
		},
		DEFAULT => -248
	},
	{#State 281
		ACTIONS => {
			'error' => 331,
			"(" => 330
		}
	},
	{#State 282
		ACTIONS => {
			'CONTEXT' => 281
		},
		DEFAULT => -234,
		GOTOS => {
			'context_expr' => 332
		}
	},
	{#State 283
		DEFAULT => -236
	},
	{#State 284
		ACTIONS => {
			'error' => 334,
			"(" => 333
		}
	},
	{#State 285
		DEFAULT => -169
	},
	{#State 286
		DEFAULT => -170
	},
	{#State 287
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'CHARACTER_LITERAL' => 206,
			'WIDE_CHARACTER_LITERAL' => 207,
			"::" => 77,
			'INTEGER_LITERAL' => 227,
			"(" => 211,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'FIXED_PT_LITERAL' => 230,
			"+" => 231,
			'error' => 336,
			"-" => 233,
			'WIDE_STRING_LITERAL' => 219,
			'FALSE' => 218,
			"~" => 234,
			'TRUE' => 221
		},
		GOTOS => {
			'string_literal' => 223,
			'primary_expr' => 225,
			'and_expr' => 226,
			'scoped_name' => 208,
			'positive_int_const' => 335,
			'wide_string_literal' => 210,
			'boolean_literal' => 212,
			'mult_expr' => 228,
			'const_exp' => 213,
			'or_expr' => 214,
			'unary_expr' => 232,
			'xor_expr' => 216,
			'shift_expr' => 217,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 288
		ACTIONS => {
			")" => 337
		}
	},
	{#State 289
		ACTIONS => {
			")" => 338
		}
	},
	{#State 290
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			"+" => 231,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"-" => 233,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"~" => 234,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'mult_expr' => 228,
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'and_expr' => 226,
			'unary_expr' => 232,
			'scoped_name' => 208,
			'xor_expr' => 339,
			'shift_expr' => 217,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 291
		DEFAULT => -274
	},
	{#State 292
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			"+" => 231,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"-" => 233,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"~" => 234,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'mult_expr' => 228,
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'and_expr' => 340,
			'unary_expr' => 232,
			'scoped_name' => 208,
			'shift_expr' => 217,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 293
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			"+" => 231,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"-" => 233,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"~" => 234,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'mult_expr' => 228,
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'unary_expr' => 232,
			'scoped_name' => 208,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 341
		}
	},
	{#State 294
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			"+" => 231,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"-" => 233,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"~" => 234,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'mult_expr' => 228,
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'unary_expr' => 232,
			'scoped_name' => 208,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 342
		}
	},
	{#State 295
		DEFAULT => -104
	},
	{#State 296
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			"+" => 231,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"-" => 233,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"~" => 234,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'mult_expr' => 343,
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'unary_expr' => 232,
			'scoped_name' => 208,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235
		}
	},
	{#State 297
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			"+" => 231,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"-" => 233,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"~" => 234,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'mult_expr' => 344,
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'unary_expr' => 232,
			'scoped_name' => 208,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235
		}
	},
	{#State 298
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			"+" => 231,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"-" => 233,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"~" => 234,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'mult_expr' => 228,
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'unary_expr' => 232,
			'scoped_name' => 208,
			'shift_expr' => 345,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 299
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			"+" => 231,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"-" => 233,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"~" => 234,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'unary_expr' => 346,
			'scoped_name' => 208,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235
		}
	},
	{#State 300
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			"+" => 231,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"-" => 233,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"~" => 234,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'unary_expr' => 347,
			'scoped_name' => 208,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235
		}
	},
	{#State 301
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'CHARACTER_LITERAL' => 206,
			"+" => 231,
			'FIXED_PT_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 207,
			"-" => 233,
			"::" => 77,
			'FALSE' => 218,
			'WIDE_STRING_LITERAL' => 219,
			'INTEGER_LITERAL' => 227,
			"~" => 234,
			"(" => 211,
			'TRUE' => 221
		},
		GOTOS => {
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'unary_expr' => 348,
			'scoped_name' => 208,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235
		}
	},
	{#State 302
		DEFAULT => -102
	},
	{#State 303
		DEFAULT => -84
	},
	{#State 304
		DEFAULT => -207
	},
	{#State 305
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'CHARACTER_LITERAL' => 206,
			'WIDE_CHARACTER_LITERAL' => 207,
			"::" => 77,
			'INTEGER_LITERAL' => 227,
			"(" => 211,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'FIXED_PT_LITERAL' => 230,
			"+" => 231,
			'error' => 350,
			"-" => 233,
			'WIDE_STRING_LITERAL' => 219,
			'FALSE' => 218,
			"~" => 234,
			'TRUE' => 221
		},
		GOTOS => {
			'string_literal' => 223,
			'primary_expr' => 225,
			'and_expr' => 226,
			'scoped_name' => 208,
			'positive_int_const' => 349,
			'wide_string_literal' => 210,
			'boolean_literal' => 212,
			'mult_expr' => 228,
			'const_exp' => 213,
			'or_expr' => 214,
			'unary_expr' => 232,
			'xor_expr' => 216,
			'shift_expr' => 217,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 306
		DEFAULT => -206
	},
	{#State 307
		DEFAULT => -136
	},
	{#State 308
		DEFAULT => -217
	},
	{#State 309
		ACTIONS => {
			"]" => 351
		}
	},
	{#State 310
		ACTIONS => {
			"]" => 352
		}
	},
	{#State 311
		DEFAULT => -209
	},
	{#State 312
		DEFAULT => -211
	},
	{#State 313
		DEFAULT => -212
	},
	{#State 314
		DEFAULT => -214
	},
	{#State 315
		DEFAULT => -200
	},
	{#State 316
		DEFAULT => -53
	},
	{#State 317
		DEFAULT => -54
	},
	{#State 318
		DEFAULT => -174
	},
	{#State 319
		ACTIONS => {
			"{" => 354,
			'error' => 353
		}
	},
	{#State 320
		ACTIONS => {
			'IDENTIFIER' => 83,
			"::" => 77
		},
		GOTOS => {
			'scoped_name' => 265,
			'interface_names' => 355,
			'interface_name' => 267
		}
	},
	{#State 321
		DEFAULT => -221
	},
	{#State 322
		ACTIONS => {
			"," => 356
		},
		DEFAULT => -225
	},
	{#State 323
		DEFAULT => -220
	},
	{#State 324
		DEFAULT => -139
	},
	{#State 325
		DEFAULT => -247
	},
	{#State 326
		ACTIONS => {
			'IDENTIFIER' => 324
		},
		GOTOS => {
			'simple_declarator' => 357
		}
	},
	{#State 327
		DEFAULT => -245
	},
	{#State 328
		DEFAULT => -251
	},
	{#State 329
		ACTIONS => {
			'OUT' => 279,
			'INOUT' => 275,
			'IN' => 273
		},
		DEFAULT => -250,
		GOTOS => {
			'param_dcl' => 280,
			'param_dcls' => 358,
			'param_attribute' => 276
		}
	},
	{#State 330
		ACTIONS => {
			'error' => 359,
			'STRING_LITERAL' => 229
		},
		GOTOS => {
			'string_literal' => 360,
			'string_literals' => 361
		}
	},
	{#State 331
		DEFAULT => -264
	},
	{#State 332
		DEFAULT => -235
	},
	{#State 333
		ACTIONS => {
			'error' => 363,
			'IDENTIFIER' => 83,
			"::" => 77
		},
		GOTOS => {
			'scoped_name' => 362,
			'exception_names' => 364,
			'exception_name' => 365
		}
	},
	{#State 334
		DEFAULT => -258
	},
	{#State 335
		ACTIONS => {
			">" => 366
		}
	},
	{#State 336
		ACTIONS => {
			">" => 367
		}
	},
	{#State 337
		DEFAULT => -91
	},
	{#State 338
		DEFAULT => -92
	},
	{#State 339
		ACTIONS => {
			"^" => 292
		},
		DEFAULT => -69
	},
	{#State 340
		ACTIONS => {
			"&" => 298
		},
		DEFAULT => -71
	},
	{#State 341
		ACTIONS => {
			"+" => 296,
			"-" => 297
		},
		DEFAULT => -76
	},
	{#State 342
		ACTIONS => {
			"+" => 296,
			"-" => 297
		},
		DEFAULT => -75
	},
	{#State 343
		ACTIONS => {
			"%" => 300,
			"*" => 299,
			"/" => 301
		},
		DEFAULT => -78
	},
	{#State 344
		ACTIONS => {
			"%" => 300,
			"*" => 299,
			"/" => 301
		},
		DEFAULT => -79
	},
	{#State 345
		ACTIONS => {
			"<<" => 293,
			">>" => 294
		},
		DEFAULT => -73
	},
	{#State 346
		DEFAULT => -81
	},
	{#State 347
		DEFAULT => -83
	},
	{#State 348
		DEFAULT => -82
	},
	{#State 349
		ACTIONS => {
			">" => 368
		}
	},
	{#State 350
		ACTIONS => {
			">" => 369
		}
	},
	{#State 351
		DEFAULT => -218
	},
	{#State 352
		DEFAULT => -219
	},
	{#State 353
		DEFAULT => -173
	},
	{#State 354
		ACTIONS => {
			'error' => 373,
			'CASE' => 370,
			'DEFAULT' => 372
		},
		GOTOS => {
			'case_labels' => 375,
			'switch_body' => 374,
			'case' => 371,
			'case_label' => 376
		}
	},
	{#State 355
		DEFAULT => -46
	},
	{#State 356
		ACTIONS => {
			'IDENTIFIER' => 324
		},
		GOTOS => {
			'simple_declarators' => 377,
			'simple_declarator' => 322
		}
	},
	{#State 357
		DEFAULT => -252
	},
	{#State 358
		DEFAULT => -249
	},
	{#State 359
		ACTIONS => {
			")" => 378
		}
	},
	{#State 360
		ACTIONS => {
			"," => 379
		},
		DEFAULT => -265
	},
	{#State 361
		ACTIONS => {
			")" => 380
		}
	},
	{#State 362
		ACTIONS => {
			"::" => 147
		},
		DEFAULT => -261
	},
	{#State 363
		ACTIONS => {
			")" => 381
		}
	},
	{#State 364
		ACTIONS => {
			")" => 382
		}
	},
	{#State 365
		ACTIONS => {
			"," => 383
		},
		DEFAULT => -259
	},
	{#State 366
		DEFAULT => -272
	},
	{#State 367
		DEFAULT => -273
	},
	{#State 368
		DEFAULT => -204
	},
	{#State 369
		DEFAULT => -205
	},
	{#State 370
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 224,
			'CHARACTER_LITERAL' => 206,
			'WIDE_CHARACTER_LITERAL' => 207,
			"::" => 77,
			'INTEGER_LITERAL' => 227,
			"(" => 211,
			'IDENTIFIER' => 83,
			'STRING_LITERAL' => 229,
			'FIXED_PT_LITERAL' => 230,
			"+" => 231,
			'error' => 385,
			"-" => 233,
			'WIDE_STRING_LITERAL' => 219,
			'FALSE' => 218,
			"~" => 234,
			'TRUE' => 221
		},
		GOTOS => {
			'mult_expr' => 228,
			'string_literal' => 223,
			'boolean_literal' => 212,
			'primary_expr' => 225,
			'const_exp' => 384,
			'and_expr' => 226,
			'or_expr' => 214,
			'unary_expr' => 232,
			'scoped_name' => 208,
			'xor_expr' => 216,
			'shift_expr' => 217,
			'wide_string_literal' => 210,
			'literal' => 220,
			'unary_operator' => 235,
			'add_expr' => 222
		}
	},
	{#State 371
		ACTIONS => {
			'CASE' => 370,
			'DEFAULT' => 372
		},
		DEFAULT => -182,
		GOTOS => {
			'case_labels' => 375,
			'switch_body' => 386,
			'case' => 371,
			'case_label' => 376
		}
	},
	{#State 372
		ACTIONS => {
			'error' => 387,
			":" => 388
		}
	},
	{#State 373
		ACTIONS => {
			"}" => 389
		}
	},
	{#State 374
		ACTIONS => {
			"}" => 390
		}
	},
	{#State 375
		ACTIONS => {
			'CHAR' => 69,
			'OBJECT' => 70,
			'FIXED' => 44,
			'SEQUENCE' => 46,
			'STRUCT' => 5,
			'DOUBLE' => 74,
			'LONG' => 75,
			'STRING' => 76,
			"::" => 77,
			'WSTRING' => 79,
			'UNSIGNED' => 55,
			'SHORT' => 57,
			'BOOLEAN' => 81,
			'IDENTIFIER' => 83,
			'UNION' => 15,
			'WCHAR' => 58,
			'FLOAT' => 66,
			'OCTET' => 64,
			'ENUM' => 27,
			'ANY' => 68
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 45,
			'char_type' => 47,
			'object_type' => 48,
			'octet_type' => 49,
			'scoped_name' => 50,
			'wide_char_type' => 51,
			'signed_long_int' => 52,
			'type_spec' => 391,
			'string_type' => 56,
			'struct_header' => 12,
			'element_spec' => 392,
			'unsigned_longlong_int' => 59,
			'any_type' => 60,
			'base_type_spec' => 61,
			'enum_type' => 62,
			'enum_header' => 19,
			'union_header' => 23,
			'unsigned_short_int' => 65,
			'signed_longlong_int' => 67,
			'wide_string_type' => 71,
			'boolean_type' => 73,
			'integer_type' => 72,
			'signed_short_int' => 78,
			'struct_type' => 80,
			'union_type' => 82,
			'sequence_type' => 84,
			'unsigned_long_int' => 85,
			'template_type_spec' => 86,
			'constr_type_spec' => 87,
			'simple_type_spec' => 88,
			'fixed_pt_type' => 89
		}
	},
	{#State 376
		ACTIONS => {
			'CASE' => 370,
			'DEFAULT' => 372
		},
		DEFAULT => -186,
		GOTOS => {
			'case_labels' => 393,
			'case_label' => 376
		}
	},
	{#State 377
		DEFAULT => -226
	},
	{#State 378
		DEFAULT => -263
	},
	{#State 379
		ACTIONS => {
			'STRING_LITERAL' => 229
		},
		GOTOS => {
			'string_literal' => 360,
			'string_literals' => 394
		}
	},
	{#State 380
		DEFAULT => -262
	},
	{#State 381
		DEFAULT => -257
	},
	{#State 382
		DEFAULT => -256
	},
	{#State 383
		ACTIONS => {
			'IDENTIFIER' => 83,
			"::" => 77
		},
		GOTOS => {
			'scoped_name' => 362,
			'exception_names' => 395,
			'exception_name' => 365
		}
	},
	{#State 384
		ACTIONS => {
			'error' => 396,
			":" => 397
		}
	},
	{#State 385
		DEFAULT => -190
	},
	{#State 386
		DEFAULT => -183
	},
	{#State 387
		DEFAULT => -192
	},
	{#State 388
		DEFAULT => -191
	},
	{#State 389
		DEFAULT => -172
	},
	{#State 390
		DEFAULT => -171
	},
	{#State 391
		ACTIONS => {
			'IDENTIFIER' => 154
		},
		GOTOS => {
			'declarator' => 398,
			'simple_declarator' => 152,
			'array_declarator' => 153,
			'complex_declarator' => 151
		}
	},
	{#State 392
		ACTIONS => {
			'error' => 400,
			";" => 399
		}
	},
	{#State 393
		DEFAULT => -187
	},
	{#State 394
		DEFAULT => -266
	},
	{#State 395
		DEFAULT => -260
	},
	{#State 396
		DEFAULT => -189
	},
	{#State 397
		DEFAULT => -188
	},
	{#State 398
		DEFAULT => -193
	},
	{#State 399
		DEFAULT => -184
	},
	{#State 400
		DEFAULT => -185
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
			$_[0]->Error("Empty specification\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 69 "parser21.yp"
{
			$_[0]->Error("definition declaration excepted.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 75 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 76 "parser21.yp"
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
#line 87 "parser21.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 12
		 'definition', 2,
sub
#line 93 "parser21.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 99 "parser21.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 105 "parser21.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 111 "parser21.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'module', 4,
sub
#line 121 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->configure('list_decl' => $_[3])
					if (defined $_[1]);
		}
	],
	[#Rule 17
		 'module', 4,
sub
#line 127 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 18
		 'module', 2,
sub
#line 133 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 142 "parser21.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 148 "parser21.yp"
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
#line 163 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	[]);
		}
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 169 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	$_[3]);
		}
	],
	[#Rule 25
		 'interface_dcl', 4,
sub
#line 175 "parser21.yp"
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
#line 186 "parser21.yp"
{
			new ForwardInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 27
		 'forward_dcl', 2,
sub
#line 192 "parser21.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'interface_header', 2,
sub
#line 201 "parser21.yp"
{
			new Interface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 29
		 'interface_header', 3,
sub
#line 207 "parser21.yp"
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
#line 221 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 32
		 'exports', 2,
sub
#line 222 "parser21.yp"
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
#line 233 "parser21.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 39
		 'export', 2,
sub
#line 239 "parser21.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 40
		 'export', 2,
sub
#line 245 "parser21.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 41
		 'export', 2,
sub
#line 251 "parser21.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 42
		 'export', 2,
sub
#line 257 "parser21.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 43
		 'interface_inheritance_spec', 2,
sub
#line 266 "parser21.yp"
{ $_[2]; }
	],
	[#Rule 44
		 'interface_inheritance_spec', 2,
sub
#line 268 "parser21.yp"
{
			$_[0]->Error("Interface name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 45
		 'interface_names', 1,
sub
#line 275 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 46
		 'interface_names', 3,
sub
#line 276 "parser21.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 47
		 'interface_name', 1,
sub
#line 281 "parser21.yp"
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
#line 290 "parser21.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 50
		 'scoped_name', 2,
sub
#line 294 "parser21.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 51
		 'scoped_name', 3,
sub
#line 300 "parser21.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 52
		 'scoped_name', 3,
sub
#line 304 "parser21.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 53
		 'const_dcl', 5,
sub
#line 314 "parser21.yp"
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
#line 322 "parser21.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 55
		 'const_dcl', 4,
sub
#line 327 "parser21.yp"
{
			$_[0]->Error("'=' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 56
		 'const_dcl', 3,
sub
#line 332 "parser21.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 57
		 'const_dcl', 2,
sub
#line 337 "parser21.yp"
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
#line 354 "parser21.yp"
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
#line 368 "parser21.yp"
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
#line 377 "parser21.yp"
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
#line 386 "parser21.yp"
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
#line 395 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 76
		 'shift_expr', 3,
sub
#line 399 "parser21.yp"
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
#line 408 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 79
		 'add_expr', 3,
sub
#line 412 "parser21.yp"
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
#line 421 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 82
		 'mult_expr', 3,
sub
#line 425 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 83
		 'mult_expr', 3,
sub
#line 429 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 84
		 'unary_expr', 2,
sub
#line 437 "parser21.yp"
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
#line 453 "parser21.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 90
		 'primary_expr', 1,
sub
#line 459 "parser21.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 91
		 'primary_expr', 3,
sub
#line 463 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 92
		 'primary_expr', 3,
sub
#line 467 "parser21.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 93
		 'literal', 1,
sub
#line 476 "parser21.yp"
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
#line 483 "parser21.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 95
		 'literal', 1,
sub
#line 489 "parser21.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 96
		 'literal', 1,
sub
#line 495 "parser21.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 97
		 'literal', 1,
sub
#line 501 "parser21.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 98
		 'literal', 1,
sub
#line 507 "parser21.yp"
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
#line 514 "parser21.yp"
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
#line 525 "parser21.yp"
{ $_[1] . $_[2]; }
	],
	[#Rule 103
		 'wide_string_literal', 1, undef
	],
	[#Rule 104
		 'wide_string_literal', 2,
sub
#line 531 "parser21.yp"
{ $_[1] . $_[2]; }
	],
	[#Rule 105
		 'boolean_literal', 1,
sub
#line 537 "parser21.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 106
		 'boolean_literal', 1,
sub
#line 543 "parser21.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 107
		 'positive_int_const', 1,
sub
#line 553 "parser21.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 108
		 'type_dcl', 2,
sub
#line 564 "parser21.yp"
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
#line 571 "parser21.yp"
{
			$_[0]->Error("type_declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 113
		 'type_declarator', 2,
sub
#line 580 "parser21.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 114
		 'type_declarator', 2,
sub
#line 587 "parser21.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 115
		 'type_spec', 1, undef
	],
	[#Rule 116
		 'type_spec', 1, undef
	],
	[#Rule 117
		 'simple_type_spec', 1, undef
	],
	[#Rule 118
		 'simple_type_spec', 1, undef
	],
	[#Rule 119
		 'simple_type_spec', 1,
sub
#line 604 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
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
		 'template_type_spec', 1, undef
	],
	[#Rule 129
		 'template_type_spec', 1, undef
	],
	[#Rule 130
		 'template_type_spec', 1, undef
	],
	[#Rule 131
		 'template_type_spec', 1, undef
	],
	[#Rule 132
		 'constr_type_spec', 1, undef
	],
	[#Rule 133
		 'constr_type_spec', 1, undef
	],
	[#Rule 134
		 'constr_type_spec', 1, undef
	],
	[#Rule 135
		 'declarators', 1,
sub
#line 638 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 136
		 'declarators', 3,
sub
#line 639 "parser21.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 137
		 'declarator', 1,
sub
#line 644 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 138
		 'declarator', 1, undef
	],
	[#Rule 139
		 'simple_declarator', 1, undef
	],
	[#Rule 140
		 'complex_declarator', 1, undef
	],
	[#Rule 141
		 'floating_pt_type', 1,
sub
#line 661 "parser21.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 142
		 'floating_pt_type', 1,
sub
#line 667 "parser21.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 143
		 'floating_pt_type', 2,
sub
#line 673 "parser21.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 144
		 'integer_type', 1, undef
	],
	[#Rule 145
		 'integer_type', 1, undef
	],
	[#Rule 146
		 'signed_int', 1, undef
	],
	[#Rule 147
		 'signed_int', 1, undef
	],
	[#Rule 148
		 'signed_int', 1, undef
	],
	[#Rule 149
		 'signed_short_int', 1,
sub
#line 696 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 150
		 'signed_long_int', 1,
sub
#line 706 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 151
		 'signed_longlong_int', 2,
sub
#line 716 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 152
		 'unsigned_int', 1, undef
	],
	[#Rule 153
		 'unsigned_int', 1, undef
	],
	[#Rule 154
		 'unsigned_int', 1, undef
	],
	[#Rule 155
		 'unsigned_short_int', 2,
sub
#line 733 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 156
		 'unsigned_long_int', 2,
sub
#line 743 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 157
		 'unsigned_longlong_int', 3,
sub
#line 753 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 158
		 'char_type', 1,
sub
#line 763 "parser21.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 159
		 'wide_char_type', 1,
sub
#line 773 "parser21.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 160
		 'boolean_type', 1,
sub
#line 783 "parser21.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'octet_type', 1,
sub
#line 793 "parser21.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'any_type', 1,
sub
#line 803 "parser21.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'object_type', 1,
sub
#line 813 "parser21.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 164
		 'struct_type', 4,
sub
#line 823 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 165
		 'struct_type', 4,
sub
#line 830 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 166
		 'struct_header', 2,
sub
#line 839 "parser21.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 167
		 'member_list', 1,
sub
#line 848 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 168
		 'member_list', 2,
sub
#line 849 "parser21.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 169
		 'member', 3,
sub
#line 855 "parser21.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 170
		 'member', 3,
sub
#line 862 "parser21.yp"
{
			$_[0]->Error("';' excepted.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 171
		 'union_type', 8,
sub
#line 875 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			);
		}
	],
	[#Rule 172
		 'union_type', 8,
sub
#line 883 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 173
		 'union_type', 6,
sub
#line 889 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 174
		 'union_type', 5,
sub
#line 895 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 175
		 'union_type', 3,
sub
#line 901 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 176
		 'union_header', 2,
sub
#line 910 "parser21.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 177
		 'switch_type_spec', 1, undef
	],
	[#Rule 178
		 'switch_type_spec', 1, undef
	],
	[#Rule 179
		 'switch_type_spec', 1, undef
	],
	[#Rule 180
		 'switch_type_spec', 1, undef
	],
	[#Rule 181
		 'switch_type_spec', 1,
sub
#line 924 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 182
		 'switch_body', 1,
sub
#line 931 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 183
		 'switch_body', 2,
sub
#line 932 "parser21.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 184
		 'case', 3,
sub
#line 938 "parser21.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 185
		 'case', 3,
sub
#line 945 "parser21.yp"
{
			$_[0]->Error("';' excepted.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 186
		 'case_labels', 1,
sub
#line 956 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 187
		 'case_labels', 2,
sub
#line 957 "parser21.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 188
		 'case_label', 3,
sub
#line 963 "parser21.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 189
		 'case_label', 3,
sub
#line 967 "parser21.yp"
{
			$_[0]->Error("':' excepted.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 190
		 'case_label', 2,
sub
#line 973 "parser21.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 191
		 'case_label', 2,
sub
#line 978 "parser21.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 192
		 'case_label', 2,
sub
#line 982 "parser21.yp"
{
			$_[0]->Error("':' excepted.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 193
		 'element_spec', 2,
sub
#line 992 "parser21.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 194
		 'enum_type', 4,
sub
#line 1003 "parser21.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 195
		 'enum_type', 4,
sub
#line 1010 "parser21.yp"
{
			$_[0]->Error("enumerator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 196
		 'enum_type', 2,
sub
#line 1015 "parser21.yp"
{
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 197
		 'enum_header', 2,
sub
#line 1023 "parser21.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 198
		 'enum_header', 2,
sub
#line 1029 "parser21.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 199
		 'enumerators', 1,
sub
#line 1036 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 200
		 'enumerators', 3,
sub
#line 1037 "parser21.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 201
		 'enumerators', 2,
sub
#line 1039 "parser21.yp"
{
			$_[0]->Warning("',' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 202
		 'enumerators', 2,
sub
#line 1044 "parser21.yp"
{
			$_[0]->Error("';' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 203
		 'enumerator', 1,
sub
#line 1053 "parser21.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 204
		 'sequence_type', 6,
sub
#line 1063 "parser21.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 205
		 'sequence_type', 6,
sub
#line 1071 "parser21.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 206
		 'sequence_type', 4,
sub
#line 1076 "parser21.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 207
		 'sequence_type', 4,
sub
#line 1083 "parser21.yp"
{
			$_[0]->Error("simple_type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 208
		 'sequence_type', 2,
sub
#line 1088 "parser21.yp"
{
			$_[0]->Error("'<' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 209
		 'string_type', 4,
sub
#line 1097 "parser21.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 210
		 'string_type', 1,
sub
#line 1104 "parser21.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 211
		 'string_type', 4,
sub
#line 1110 "parser21.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 212
		 'wide_string_type', 4,
sub
#line 1119 "parser21.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 213
		 'wide_string_type', 1,
sub
#line 1126 "parser21.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 214
		 'wide_string_type', 4,
sub
#line 1132 "parser21.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 215
		 'array_declarator', 2,
sub
#line 1140 "parser21.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 216
		 'fixed_array_sizes', 1,
sub
#line 1144 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 217
		 'fixed_array_sizes', 2,
sub
#line 1146 "parser21.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 218
		 'fixed_array_size', 3,
sub
#line 1151 "parser21.yp"
{ $_[2]; }
	],
	[#Rule 219
		 'fixed_array_size', 3,
sub
#line 1153 "parser21.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 220
		 'attr_dcl', 4,
sub
#line 1162 "parser21.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 221
		 'attr_dcl', 4,
sub
#line 1170 "parser21.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 222
		 'attr_dcl', 3,
sub
#line 1175 "parser21.yp"
{
			$_[0]->Error("type excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 223
		 'attr_mod', 1, undef
	],
	[#Rule 224
		 'attr_mod', 0, undef
	],
	[#Rule 225
		 'simple_declarators', 1,
sub
#line 1187 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 226
		 'simple_declarators', 3,
sub
#line 1189 "parser21.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 227
		 'except_dcl', 3,
sub
#line 1195 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 228
		 'except_dcl', 4,
sub
#line 1200 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 229
		 'except_dcl', 4,
sub
#line 1208 "parser21.yp"
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
	[#Rule 230
		 'except_dcl', 2,
sub
#line 1218 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 231
		 'exception_header', 2,
sub
#line 1227 "parser21.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 232
		 'exception_header', 2,
sub
#line 1233 "parser21.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 233
		 'op_dcl', 2,
sub
#line 1242 "parser21.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 234
		 'op_dcl', 3,
sub
#line 1251 "parser21.yp"
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
	[#Rule 235
		 'op_dcl', 4,
sub
#line 1261 "parser21.yp"
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
	[#Rule 236
		 'op_dcl', 3,
sub
#line 1272 "parser21.yp"
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
	[#Rule 237
		 'op_dcl', 2,
sub
#line 1282 "parser21.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 238
		 'op_header', 3,
sub
#line 1292 "parser21.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 239
		 'op_header', 3,
sub
#line 1300 "parser21.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 240
		 'op_mod', 1, undef
	],
	[#Rule 241
		 'op_mod', 0, undef
	],
	[#Rule 242
		 'op_attribute', 1, undef
	],
	[#Rule 243
		 'op_type_spec', 1, undef
	],
	[#Rule 244
		 'op_type_spec', 1,
sub
#line 1320 "parser21.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 245
		 'parameter_dcls', 3,
sub
#line 1330 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 246
		 'parameter_dcls', 2,
sub
#line 1334 "parser21.yp"
{
			undef;
		}
	],
	[#Rule 247
		 'parameter_dcls', 3,
sub
#line 1338 "parser21.yp"
{
			$_[0]->Error("parameters declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 248
		 'param_dcls', 1,
sub
#line 1345 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 249
		 'param_dcls', 3,
sub
#line 1346 "parser21.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 250
		 'param_dcls', 2,
sub
#line 1348 "parser21.yp"
{
			$_[0]->Warning("',' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 251
		 'param_dcls', 2,
sub
#line 1353 "parser21.yp"
{
			$_[0]->Error("';' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 252
		 'param_dcl', 3,
sub
#line 1362 "parser21.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
        }
	],
	[#Rule 253
		 'param_attribute', 1, undef
	],
	[#Rule 254
		 'param_attribute', 1, undef
	],
	[#Rule 255
		 'param_attribute', 1, undef
	],
	[#Rule 256
		 'raises_expr', 4,
sub
#line 1381 "parser21.yp"
{
			$_[3];
		}
	],
	[#Rule 257
		 'raises_expr', 4,
sub
#line 1385 "parser21.yp"
{
			$_[0]->Error("name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 258
		 'raises_expr', 2,
sub
#line 1390 "parser21.yp"
{
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 259
		 'exception_names', 1,
sub
#line 1397 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 260
		 'exception_names', 3,
sub
#line 1398 "parser21.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 261
		 'exception_name', 1,
sub
#line 1403 "parser21.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 262
		 'context_expr', 4,
sub
#line 1411 "parser21.yp"
{
			$_[3];
		}
	],
	[#Rule 263
		 'context_expr', 4,
sub
#line 1415 "parser21.yp"
{
			$_[0]->Error("string excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 264
		 'context_expr', 2,
sub
#line 1420 "parser21.yp"
{
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 265
		 'string_literals', 1,
sub
#line 1427 "parser21.yp"
{ [$_[1]]; }
	],
	[#Rule 266
		 'string_literals', 3,
sub
#line 1428 "parser21.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 267
		 'param_type_spec', 1, undef
	],
	[#Rule 268
		 'param_type_spec', 1, undef
	],
	[#Rule 269
		 'param_type_spec', 1, undef
	],
	[#Rule 270
		 'param_type_spec', 1, undef
	],
	[#Rule 271
		 'param_type_spec', 1,
sub
#line 1438 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 272
		 'fixed_pt_type', 6,
sub
#line 1446 "parser21.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 273
		 'fixed_pt_type', 6,
sub
#line 1454 "parser21.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 274
		 'fixed_pt_type', 4,
sub
#line 1459 "parser21.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 275
		 'fixed_pt_type', 2,
sub
#line 1464 "parser21.yp"
{
			$_[0]->Error("'<' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 276
		 'fixed_pt_const_type', 1,
sub
#line 1473 "parser21.yp"
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

#line 1480 "parser21.yp"


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
