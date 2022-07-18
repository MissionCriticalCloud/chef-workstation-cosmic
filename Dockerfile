FROM chef/chefworkstation:22.7.1007

# Accept the license without prompting
ARG CHEF_LICENSE=accept

# Set any build variables here
ARG VAGRANT_VERSION=2.2.19

ARG VAGRANT_GEMDIR=/opt/vagrant/embedded/gems/${VAGRANT_VERSION}/
ARG CHEF_GEMDIR=/opt/chef-workstation/embedded/lib/ruby/gems/3.0.0/

ARG NET_SSH_PATCH1=f79ed49dc068317fb280bd2fb554ecb0ce13a7e1 
ARG NET_SSH_PATCH2=a45f54fe1de434605af0b7195dd9a91bccd2cec5"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Print Chef-Workstation component versions
RUN /opt/chef-workstation/bin/chef -v

RUN echo "Installing dependencies..." \
 && apt-get -qq update \
 && apt-get -qq upgrade \
 && apt-get -qq install --no-install-recommends -y \
        build-essential \
        unzip \
        patchutils \
 && apt-get clean \
 && rm -rf /tmp/* /var/cache/debconf/*-old /var/lib/apt/lists/* \
        /var/lib/dpkg/*-old /var/log/*log /var/log/apt/* /var/tmp/*

RUN echo "Installing vagrant ${VAGRANT_VERSION}..." \
 && VAGRANT_DEB="vagrant_${VAGRANT_VERSION}_x86_64.deb" \
 && curl -sLo /tmp/$VAGRANT_DEB https://releases.hashicorp.com/vagrant/$VAGRANT_VERSION/$VAGRANT_DEB \
 && dpkg -i /tmp/$VAGRANT_DEB && rm -rf /tmp/$VAGRANT_DEB \
 && vagrant plugin install vagrant-cosmic \
 && vagrant plugin install vagrant-vsphere

# Monkey patch Berkshelf to print errors returned by Chef-Guard, this can be removed when
# https://github.com/berkshelf/berkshelf/pull/1827 has been merged.
RUN echo "Monkey patching Berkshelf (see https://github.com/berkshelf/berkshelf/pull/1827)..." \
 && sed -i -e 's/Berkshelf.formatter.skipping(cookbook, connection)/Berkshelf.formatter.skipping(cookbook, connection)\nrescue Net::HTTPClientException => e\nputs e.response.body/' \
        /opt/chef-workstation/embedded/lib/ruby/gems/*/gems/berkshelf-*/lib/berkshelf/uploader.rb

# Enterprise Linux 9 (RHEL/AlmaLinux/Rocky) ship with ssh-rsa signatures disabled.
# For more details see https://www.openssh.com/txt/release-8.7
#
# The ruby gem net-ssh needs to be updated to 6.3.0.beta1 + patch to handle this.
# Future releases of test-kitchen and vagrant will probably handle this better.
RUN /opt/vagrant/embedded/bin/gem install net-ssh -v 6.3.0.beta1 --pre --install-dir ${VAGRANT_GEMDIR} && \
    /opt/chef-workstation/embedded/bin/gem install net-ssh -v 6.3.0.beta1 --pre --no-user-install  --install-dir ${CHEF_GEMDIR} && \
    sed -i 's/gem "net-ssh", "= 6.1.0"/gem "net-ssh", "= 6.3.0.beta1"/' /opt/chef-workstation/bin/kitchen && \
    curl https://github.com/net-ssh/net-ssh/commit/${NET_SSH_PATCH1}.diff | filterdiff -p1 -x 'test/*' -x '.rubocop_todo.yml' | \
      patch -p1 -d ${VAGRANT_GEMDIR}/gems/net-ssh-6.3.0.beta1 && \
    curl https://github.com/net-ssh/net-ssh/commit/${NET_SSH_PATCH2}.diff | filterdiff -p1 -x 'test/*' -x '.rubocop_todo.yml' | \
      patch -p1 -d ${VAGRANT_GEMDIR}/gems/net-ssh-6.3.0.beta1 && \
    curl https://github.com/net-ssh/net-ssh/commit/${NET_SSH_PATCH1}.diff | filterdiff -p1 -x 'test/*' -x '.rubocop_todo.yml' | \
      patch -p1 -d ${CHEF_GEMDIR}/gems/net-ssh-6.3.0.beta1 && \
    curl https://github.com/net-ssh/net-ssh/commit/${NET_SSH_PATCH2}.diff | filterdiff -p1 -x 'test/*' -x '.rubocop_todo.yml' | \
      patch -p1 -d ${CHEF_GEMDIR}/gems/net-ssh-6.3.0.beta1

# Create directory and install knife-spork for cookbook deployment
RUN mkdir -p ~/environments \
 && chef gem install knife-spork

# Setup entrypoint
COPY docker-entrypoint.sh /usr/bin
ENTRYPOINT ["docker-entrypoint.sh"]
