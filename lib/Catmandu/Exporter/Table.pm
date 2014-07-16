package Catmandu::Exporter::Table;

our $VERSION = '0.2.1';

use namespace::clean;
use Catmandu::Sane;
use Moo;
use Text::MarkdownTable;
use IO::Handle::Util ();
use IO::File;
use JSON ();

with 'Catmandu::Exporter';

# JSON Table Schema
has schema => (
    is => 'ro',
    coerce => sub {
        my $schema = $_[0];
        unless (ref $schema and ref $schema eq 'HASH') {
            $schema = \*STDIN if $schema eq '-';
            my $fh = ref $schema 
                    ? IO::Handle::Util::io_from_ref($schema) 
                    : IO::File->new($schema, "r");
            die "failed to load JSON Table Schema from $schema" unless $fh;
            local $/; 
            $schema = JSON::decode_json(<$fh>);
        }
        $schema;
    }
);

has fields => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        return unless $_[0]->schema;
        [ map { $_->{name} } @{$_[0]->schema->{fields}} ];
    }
);
has columns => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        return unless $_[0]->schema;
        [ map { $_->{title} // $_->{name} } @{$_[0]->schema->{fields}} ];
    }
);

has widths   => (is => 'ro');
has condense => (is => 'ro');

has _table => (
    is      => 'lazy',
    default => sub {
        Text::MarkdownTable->new(
            file => $_[0]->fh,
            map { $_ => $_[0]->$_ }
            grep { defined $_[0]->$_ }
            qw(fields columns widths condense)
        );
    },
);

sub add { 
    $_[0]->_table->add($_[1]) 
}

sub commit { 
    $_[0]->_table->done 
}

=head1 NAME

Catmandu::Exporter::Table - ASCII/Markdown table exporter

=head1 SYNOPSIS

  echo '{"one":"my","two":"table"} {"one":"is","two":"nice"}]' | \ 
  catmandu convert JSON --multiline 1 to Table
  | one | two   |
  |-----|-------|
  | my  | table |
  | is  | nice  |

  catmandu convert CSV to Table --fields id,name --header ID,Name < sample.csv
  | ID | Name |
  |----|------|
  | 23 | foo  |
  | 42 | bar  |
  | 99 | doz  |


  #!/usr/bin/env perl
  use Catmandu::Exporter::Table;
  my $exp = Catmandu::Exporter::Table->new;
  $exp->add({ title => "The Hobbit", author => "Tolkien" });
  $exp->add({ title => "Where the Wild Things Are", author => "Sendak" });
  $exp->add({ title => "One Thousand and One Nights" });
  $exp->commit;

  | author  | title                       |
  |---------|-----------------------------|
  | Tolkien | The Hobbit                  |
  | Sendak  | Where the Wild Things Are   |
  |         | One Thousand and One Nights |


=head1 DESCRIPTION

This L<Catmandu::Exporter> exports data in tabular form, formatted in
MultiMarkdown syntax.

The output can be used for simple display, for instance to preview Excel files
on the command line. Use L<Pandoc|http://johnmacfarlane.net/pandoc/> too
further convert to other table formats, e.g. C<latex>, C<html5>, C<mediawiki>:

    catmandu convert XLS to Table < sheet.xls | pandoc -t html5

=head1 CONFIGURATION

Table output can be controlled with the options C<fields>, C<columns>,
C<widths>, and C<condense> as documented in L<Text::MarkdownTable>. The
additional option C<schema> can be used to supply fields and (optionally)
columns in a L<JSON Table Schema|http://dataprotocols.org/json-table-schema/>.
The schema is a JSON file or HASH reference having the following structure:

  {
    "fields: [
      { "name": "field-name-1", "title": "column title 1 (optional)" },
      { "name": "field-name-2", "title": "column title 2 (optional)" },
      ...
    ]
  }

Without C<fields> or C<schema>, columns are sorted alphabetically by field
name.

=head1 METHODS

See L<Catmandu::Exporter> for additional exporter and methods (C<file>, C<fh>,
C<encoding>, C<fix>..., C<add>, C<commit>...).

=head1 SEE ALSO

L<Text::MarkdownTable>, 
L<Catmandu::Exporter::CSV>

=cut

1;
