use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::IDL',
    'VERSION_FROM'  => 'node.pm',
    'ABSTRACT'      => 'CORBA-IDL parser',
    'PREREQ_PM'     => {},
    'PM'            => {
                        'ascii.pm'      => '$(INST_LIBDIR)/IDL/ascii.pm',
                        'lexer.pm'      => '$(INST_LIBDIR)/IDL/lexer.pm',
                        'node.pm'       => '$(INST_LIBDIR)/IDL/node.pm',
                        'parser20.pm'   => '$(INST_LIBDIR)/IDL/parser20.pm',
                        'parser21.pm'   => '$(INST_LIBDIR)/IDL/parser21.pm',
                        'parser22.pm'   => '$(INST_LIBDIR)/IDL/parser22.pm',
                        'parser23.pm'   => '$(INST_LIBDIR)/IDL/parser23.pm',
                        'parser24.pm'   => '$(INST_LIBDIR)/IDL/parser24.pm',
                        'repos_id.pm'   => '$(INST_LIBDIR)/IDL/repos_id.pm',
                        'symbtab.pm'    => '$(INST_LIBDIR)/IDL/symbtab.pm',
    },
    'EXE_FILES'     => ['idl.pl'],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);
