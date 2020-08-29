sudo yum update -y
sudo yum -y install git
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
echo '# rbenv' >> ~/.bash_profile
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
source ~/.bash_profile
# モジュールインストール
sudo yum -y install bzip2 gcc gcc-c++ openssl-devel readline-devel zlib-devel mysql mysql-devel tmux libxml2 libxml2-devel libcurl libcurl-devel
# imagemagick系
sudo yum install -y libtiff graphviz ImageMagick6 ImageMagick6-devel ImageMagick6-libs --enablerepo=remi,epel,base

# cloud watch メモリ監視
sudo yum -y install perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64
sudo mkdir /usr/local/cloudwatch
cd /usr/local/cloudwatch
sudo curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
sudo unzip -f CloudWatchMonitoringScripts-1.2.2.zip && \
sudo rm -rf CloudWatchMonitoringScripts-1.2.2.zip && \
cd aws-scripts-mon
sudo cp -f awscreds.template awscreds.conf

# kinesis agent
sudo yum –y install https://s3.amazonaws.com/streaming-data-agent/aws-kinesis-agent-latest.amzn1.noarch.rpm
sudo service aws-kinesis-agent start
sudo service aws-kinesis-agent enable

# rediscli
# https://qiita.com/stoshiya/items/b8c1d2eb41770f92ffcf
sudo yum install -y redis

rbenv install -s 2.7.1
rbenv global 2.7.1
gem install bundler
# gem install rails

sudo yum install -y nginx
sudo service nginx start
sudo service redis start

curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
curl --silent --location https://rpm.nodesource.com/setup_12.x | sudo bash -
sudo yum -y install yarn
sudo yum -y install awslogs
#  https://stackoverflow.com/questions/41991872/having-trouble-installing-awslogs-agent
sudo service awslogsd start
sudo service awslogsd.service enable

# https://eng-entrance.com/linux-command-chmod
# o: ユーザ +: 追加 x: 実行
sudo chmod o+x /var/lib/nginx/
sudo chmod o+x /var/lib/nginx/tmp
sudo chmod o+x /var/lib/nginx/tmp/client_body

echo "alias nginx_restart='sudo nginx -s stop; sudo service nginx start'" >> ~/.bashrc
echo "alias nginx_access_log='sudo sh -c \"tail -f /var/log/nginx/access.log\"'" >> ~/.bashrc
echo "alias nginx_error_log='sudo sh -c \"tail -f /var/log/nginx/error.log\"'" >> ~/.bashrc
echo "alias ll='ls -la'" >> ~/.bashrc
echo "alias besides='cd /var/www/besides_api/current/'" >> ~/.bashrc
echo "alias log='tail -f /var/www/besides_api/current/log/staging.log'" >> ~/.bashrc
echo "alias shared='cd /var/www/besides_api/shared/'" >> ~/.bashrc
echo "alias rc='bundle exec rails c -e staging'" >> ~/.bashrc
echo "alias rcre='bundle exec rails db:create RAILS_ENV=staging'" >> ~/.bashrc
echo "alias rmig='bundle exec rails db:migrate RAILS_ENV=staging'" >> ~/.bashrc
echo "alias rsf='bundle exec rails db:seed_fu RAILS_ENV=staging'" >> ~/.bashrc
echo "alias be='bundle exec'" >> ~/.bashrc
echo "alias bi='bundle install'" >> ~/.bashrc
echo "alias bu='bundle update'" >> ~/.bashrc
echo "alias cb='cat ~/.bashrc'" >> ~/.bashrc
echo "alias vb='vim ~/.bashrc'" >> ~/.bashrc
echo "alias sb='source ~/.bashrc'" >> ~/.bashrc
echo "alias rc='cd /var/www/besides_api/current/ && bundle exec rails c -e staging'" >> ~/.bashrc
echo "alias cpds='cp -r db/fixtures/development/* db/fixtures/staging/'" >> ~/.bashrc
echo "export RAILS_ENV='staging'" >> ~/.bashrc
sudo mkdir -p /var/www/besides_api/shared/config
sudo chown -R ec2-user:ec2-user /var/www/


