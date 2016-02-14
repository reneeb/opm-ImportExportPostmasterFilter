# --
# Kernel/Output/HTML/FilterElementPost/ImportExportPostmasterFilter.pm
# Copyright (C) 2014 - 2016 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::ImportExportPostmasterFilter;

use strict;
use warnings;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{UserID} = $Param{UserID};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;

    return 1 if !first{ $Templatename eq $_ }keys %{$Param{Templates} || { AdminPostMasterFilter => 1 } };

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $Name = $ParamObject->GetParam( Param => 'Name' );

    if ( !$Name ) {
        $LayoutObject->Block(
            Name => 'Import',
        );
    }

    my $Snippet = $LayoutObject->Output(
        TemplateFile => 'ImportExportPostmasterFilterWidget',
        Data         => {
            Name => $Name,
        },
    );

    ${ $Param{Data} } =~ s{(</div> \s+ <div \s+ class="ContentColumn">)}{$Snippet $1}mxs;

    return ${ $Param{Data} };
}

1;
