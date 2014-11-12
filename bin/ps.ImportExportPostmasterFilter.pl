#!/usr/bin/perl

# --
# bin/ps.ImportExportPostmasterFilter.pl - import/export postmaster filter
# Copyright (C) 2013 - 2014 Perl-Services.de, http://perl-services.de
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);

use vars qw (%opts);
use Getopt::Long;

use Kernel::System::ObjectManager;

# create common objects
local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-ps.ImportExportPostmasterFilter.pl',
    },
);

GetOptions(
    'm=s' => \$opts{m},
    'f=s' => \$opts{f},
);

my $UtilObject = $Kernel::OM->Get('Kernel::System::PostMaster::ImportExport');
my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

$opts{m} ||= 'export';
$opts{m} = lc $opts{m};

if (
    ($opts{m} ne 'export' && $opts{m} ne 'import' ) || 
    ($opts{m} eq 'import' && 
        ( !$opts{f} || !-f $opts{f} )
    )
) {
    print STDERR qq~$0 [-m <mode>] [-f <file> ] [filter1 filter2 filter3]

m        mode   export or import
f        in export mode path to the file the export should be written to (optional)
         in import mode path to the file that should be imported (mandatory)
filter   in export mode the ids of filters to be exported. If those ids are ommitted, all filters are exported

Example:

  $0 -m export reject_auto_replies close_junk

  exports only the filters named reject_auto_replies and close_junk
~;
}

if ( $opts{m} eq 'export' ) {

    my $JSON = $UtilObject->PostmasterFilterExport(
        IDs => \@ARGV,
    );

    if ( !$opts{f} ) {
        print $JSON;
    }
    else {
        $MainObject->FileWrite(
            Location => $opts{f},
            Content  => \$JSON,
        );
    }
}
else {
    my $ContentRef = $MainObject->FileRead(
        Location => $opts{f},
    );

    $UtilObject->PostmasterFilterImport(
        Filters => ${$ContentRef},
        UserID  => 1,
    );
}
