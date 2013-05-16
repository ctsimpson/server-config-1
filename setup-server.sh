#!/bin/bash

source ssinclude-1

# Variables
DB_PASSWORD="p@ssw0rd"
DB_NAME=""
DB_USER=""
DB_USER_PASSWORD=""
RUBY_VERSION="ruby-1.9.3-p392"
GEMS_TO_INSTALL1="mysql,unicorn,bundler"
RAILS_VERSION="3.2.11"

while true; do
    read -p "MySQL root Password :" DB_PASSWORD
	break;
done

echo "What version of Ruby should we install?"
select rubyver in "Ruby 1.9.2" "Ruby 1.9.3"; do
    case $rubyver in
        'Ruby 1.9.2' ) RUBY_VERSION="ruby-1.9.2-rc2"; break;;
        'Ruby 1.9.3' ) RUBY_VERSION="ruby-1.9.3-p392"; break;;
    esac
done

echo "What version of Rails should we install?"
select railsver in "3.2.3" "3.2.8"; do
    case $railsver in
        '3.2.8' ) RAILS_VERSION="3.2.8"; break;;
        '3.2.11') RAILS_VERSION="3.2.11"; break;;
    esac
done

logfile="/tmp/log.txt"
rubyscript="/tmp/ruby_script_to_run.rb" 
# This script is generated and run after gem is installed to
# install the list of gems given by the stack script."

export logfile
export gems_to_install1="$GEMS_TO_INSTALL1"
# exported to be available in ruby_script_to_run.rb

echo "Begin Script" >> $logfile
system_update
echo "System Updated" >> $logfile
postfix_install_loopback_only
echo "postfix_install_loopback_only" >> $logfile
mysql_install "$DB_PASSWORD" && mysql_tune 40
echo "Mysql installed" >> $logfile
mysql_create_database "$DB_PASSWORD" "$DB_NAME"
mysql_create_user "$DB_PASSWORD" "$DB_USER" "$DB_USER_PASSWORD"
mysql_grant_user "$DB_PASSWORD" "$DB_USER" "$DB_NAME"

#installing nginx
echo -ne '\n' | apt-add-repository ppa:nginx/stable
apt-get -y update
apt-get -y install nginx
echo "Nginx installed" >> $logfile

#install nodejs
echo -ne '\n' | apt-add-repository ppa:chris-lea/node.js
apt-get -y update
apt-get -y install nodejs
echo "Nodejs installed" >> $logfile

#install imagemagick
apt-get -y install imagemagick

#installing ruby
apt-get -y install curl build-essential openssl ruby-dev libmysqlclient-dev libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison python-software-properties
echo "libs for ruby installed" >> $logfile
echo "$RUBY_VERSION.tar.gz" >> $logfile
echo "$RUBY_VERSION" >> $logfile

echo "" >> $logfile
if [[ $RUBY_VERSION == ruby\-1\.9* ]]
then
	echo "Downloading: (from calling wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/$RUBY_VERSION.tar.gz)" >> $logfile
echo "" >> $logfile
	wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/$RUBY_VERSION.tar.gz  >> $logfile
else
	echo "Downloadin: (from calling wget ftp://ftp.ruby-lang.org/pub/ruby/1.8/$RUBY_VERSION.tar.gz)" >> $logfile
echo "" >> $logfile
	wget ftp://ftp.ruby-lang.org/pub/ruby/1.8/$RUBY_VERSION.tar.gz  >> $logfile
fi

echo ""
echo "tar output:"
tar -xzvf $RUBY_VERSION.tar.gz >> $logfile
rm $RUBY_VERSION.tar.gz
cd $RUBY_VERSION

echo ""
echo "Current directory:"
pwd >> $logfile

echo "" >> $logfile
echo "Ruby Configuration output: (from calling ./configure --disable-ucontext --enable-pthread)" >> $logfile
echo "" >> $logfile
./configure >> $logfile

echo "" >> $logfile
echo "Ruby make output: (from calling make)" >> $logfile
echo "" >> $logfile
make >> $logfile

echo "" >> $logfile
echo "Ruby make install output: (from calling make install)" >> $logfile
echo "" >> $logfile
make install >> $logfile
cd /
rm -rf $RUBY_VERSION

echo "" >> $logfile
echo "Downloading Ruby Gems with wget http://production.cf.rubygems.org/rubygems/rubygems-2.0.3.tgz" >> $logfile
echo "" >> $logfile
wget http://production.cf.rubygems.org/rubygems/rubygems-2.0.3.tgz >> $logfile

echo ""
echo "tar output:"
tar xzvf rubygems-2.0.3.tgz  >> $logfile
rm rubygems-2.0.3.tgz

echo ""
echo "rubygems setup:"
cd rubygems-2.0.3
ruby setup.rb >> $logfile
cd /
rm -rf rubygems-2.0.3

#install rails
gem install rails -v $RAILS_VERSION --no-ri --no-rdoc >> $logfile

echo ""
echo "gem update --system:"
gem update --system >> $logfile

# echo the ruby code to a file to be run
echo "
    ##### Ruby Code Starts Here #####

    gems_to_install1 = ENV['gems_to_install1']
    
    puts gems_to_install1
    
    gems_to_install1.split(',').each do |gem_name|
      \`gem install #{gem_name} --no-ri --no-rdoc >> $logfile\`
    end

    ##### Ruby Code Ends Here #####" >> $rubyscript

ruby $rubyscript >> $logfile

restartServices
echo "Deploy script finished!" >> $logfile
