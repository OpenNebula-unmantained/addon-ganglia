#!/bin/bash

# -------------------------------------------------------------------------- #
# Copyright 2002-2013, OpenNebula Project Leads (OpenNebula.org)             #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

if [ -z $1 ]; then
    PREFIX=$ONE_LOCATION
else
    PREFIX=$1
fi

if [ -z "$PREFIX" ]; then
    LIB_LOCATION="/usr/lib/one/ruby"
    SHARE_LOCATION="/usr/share/one"
    REMOTES_LOCATION="/var/lib/one/remotes"
else
    LIB_LOCATION="$PREFIX/lib/ruby"
    SHARE_LOCATION="$PREFIX/share"
    REMOTES_LOCATION="$PREFIX/var/remotes"
fi

cp -R im/ganglia.d $REMOTES_LOCATION/im
cp vmm/poll_ganglia.rb $REMOTES_LOCATION/vmm/kvm/poll_ganglia
cp vmm/poll_ganglia.rb $REMOTES_LOCATION/vmm/xen3/poll_ganglia
cp vmm/poll_ganglia.rb $REMOTES_LOCATION/vmm/xen4/poll_ganglia
cp lib/Ganglia.rb $LIB_LOCATION
cp tools/push_ganglia $SHARE_LOCATION


