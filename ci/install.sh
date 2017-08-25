#!/bin/sh

#   Copyright © 2017 Teclib. All rights reserved.
#
# install.sh is part of flyve-mdm-ios
#
# flyve-mdm-ios is a subproject of Flyve MDM. Flyve MDM is a mobile
# device management software.
#
# flyve-mdm-ios is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# flyve-mdm-ios is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# ------------------------------------------------------------------------------
# @author    Hector Rondon
# @date      25/08/17
# @copyright Copyright © 2017 Teclib. All rights reserved.
# @license   GPLv3 https://www.gnu.org/licenses/gpl-3.0.html
# @link      https://github.com/flyve-mdm/flyve-mdm-ios-agent
# @link      https://.flyve-mdm.com
# ------------------------------------------------------------------------------

# Update gem
gem update --system
# install Node Version Manager
nvm install stable
# Use stable version
nvm use stable
# Install fastlane last version
gem install fastlane --no-rdoc --no-ri --no-document --quiet
# Install jq for json parse
brew install jq
# Install standard-version scope global
npm i -g standard-version
# Install conventional-github-releaser scope global
npm install -g conventional-github-releaser
# Install libs from package.json
npm install
