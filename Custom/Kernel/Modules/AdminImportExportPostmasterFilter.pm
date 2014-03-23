# --
# Kernel/Modules/AdminImportExportPostmasterFilter.pm - import/export postmaster filter
# Copyright (C) 2014 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminImportExportPostmasterFilter;

use strict;
use warnings;

use List::Util qw( first );

use Kernel::System::PostMaster::ImportExport;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $NeededData (
        qw(ParamObject DBObject LayoutObject LogObject ConfigObject MainObject EncodeObject Subaction)
        )
    {
        if ( !$Param{$NeededData} ) {
            $Param{LayoutObject}->FatalError( Message => "Got no $NeededData!" );
        }
        $Self->{$NeededData} = $Param{$NeededData};
    }

    # create necessary objects
    $Self->{ImportExportObject} = Kernel::System::PostMaster::ImportExport->new( %{$Self} );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    if ( $Self->{Subaction} eq 'Export' ) {

        my %Opts;

        my $Name = $Self->{ParamObject}->GetParam( Param => 'Name' );
        if ( $Name ) {
            $Opts{IDs} = [ $Name ];
        }

        my $JSON = $Self->{ImportExportObject}->PostmasterFilterExport(
            %Opts,
        );

        return $Self->{LayoutObject}->Attachment(
            Filename    => 'PostmasterFilter.json',
            Content     => $JSON,
            ContentType => 'text/json',
        );

    }

    # ---------------------------------------------------------- #
    # show import screen
    # ---------------------------------------------------------- #
    elsif ( $Self->{Subaction} eq 'Import' ) {

        my $Error = 0;

        # get params
        $Param{Status} = $Self->{ParamObject}->GetParam( Param => 'Status' );

        # importing
        if ( $Param{Status} && $Param{Status} eq 'Action' ) {

            # challenge token check for write action
            $Self->{LayoutObject}->ChallengeTokenCheck();

            my $Uploadfile = '';
            if ( $Uploadfile = $Self->{ParamObject}->GetParam( Param => 'file_upload' ) ) {
                my %UploadStuff = $Self->{ParamObject}->GetUploadAll(
                    Param    => 'file_upload',
                    Encoding => 'Raw'
                );

                my $Success = $Self->{ImportExportObject}->PostmasterFilterImport(
                    Filters => $UploadStuff{Content},
                );
            }
        }

        # show import form
        my $Output = $Self->{LayoutObject}->Header( Title => 'Import' );
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->{LayoutObject}->Output( TemplateFile => 'AdminImportPostmasterFilter' );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ---------------------------------------------------------- #
    # show error screen
    # ---------------------------------------------------------- #
    return $Self->{LayoutObject}->ErrorScreen( Message => 'Invalid Subaction process!' );
}

1;
