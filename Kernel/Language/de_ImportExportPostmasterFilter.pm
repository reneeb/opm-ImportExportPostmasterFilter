# --
# Kernel/Language/de_ImportExportPostmasterFilter.pm - the german translation of ImportExportPostmasterFilter
# Copyright (C) 2013 - 2023 Perl-Services, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_ImportExportPostmasterFilter;

use strict;
use warnings;

use utf8;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.1.1.1 $) [1];

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    $Lang->{Import}  = 'Importieren';
    $Lang->{Export}  = 'Exportieren';
    $Lang->{"Import Postmaster Filter"} = 'Postmaster Filter Importieren';
    $Lang->{"Import/Export"} = 'Importieren/Exportieren';

    return 1;
}

1;
