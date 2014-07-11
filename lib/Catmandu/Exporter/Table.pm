package Catmandu::Exporter::Table;

our $VERSION = '0.2.0';

use namespace::clean;
use Catmandu::Sane;
use Moo;
use Text::MarkdownTable;

with 'Catmandu::Exporter';

has fields   => (is => 'ro');
has columns  => (is => 'ro');
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
MultiMarkdown syntax. The module delegates to L<Text::MarkdownTable>, so
see the latter for more documentation.

=head1 CONFIGURATION

Table output can be controlled with the options C<fields>, C<columns>,
C<widths>, and C<condense>.

See L<Catmandu::Exporter> for additional exporter and methods (C<file>, C<fh>,
C<encoding>, C<fix>..., C<add>, C<commit>...).

=head1 SEE ALSO

L<Catmandu::Exporter::CSV>

=cut

1;
