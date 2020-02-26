#
# Copyright 2016 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Written by John Wu (jwu@web.com)
# 2018-06-13

package hardware::server::cisco::ucce::mode::component;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Data::Dumper;

my %status_map = (
    1 => ['unknown', 'UNKNOWN'],
    2 => ['disabled', 'CRITICAL'],
    3 => ['stopped', 'CRITICAL'],
    4 => ['started', 'OK'],
    5 => ['active', 'OK'],
    6 => ['standby', 'OK'],
    7 => ['disconnected', 'CRITICAL'],
    8 => ['uninitialized', 'CRITICAL'],
    9 => ['nonRoutable', 'CRITICAL'],
);

my $oid_cccaComponentName = '.1.3.6.1.4.1.9.9.473.1.2.2.1.3';
my $oid_cccaComponentStatus = '.1.3.6.1.4.1.9.9.473.1.2.2.1.4';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
        });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $result = $self->{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cccaComponentName },
            { oid => $oid_cccaComponentStatus },
        ],
        nothing_quit => 1,
    );
    #print Data::Dumper->Dump([\$result],[qw(*result)]);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cccaComponentName}})) {
        $key =~ /\.(\d+\.\d+)$/;
        my $index = $1;
        my $name = $result->{$oid_cccaComponentName}->{$oid_cccaComponentName . '.' . $index};
        my $status = $result->{$oid_cccaComponentStatus}->{$oid_cccaComponentStatus . '.' . $index};
        $self->{output}->output_add(
            severity => ${$status_map{$status}}[1], 
            short_msg => sprintf("%s is %s (%s)", $name, ${$status_map{$status}}[0], ${$status_map{$status}}[1])
        );
    }
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Components

=back

=cut
