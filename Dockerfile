FROM chef/chefworkstation:0.16.31

# Set any build variables here
ARG VAGRANT_VERSION=2.2.7

# Print Chef-Workstation component versions
RUN /opt/chef-workstation/bin/chef -v

RUN echo "Installing dependencies..." \
 && apt-get -qq update && apt-get -qq install --no-install-recommends -y build-essential && apt-get clean \
 && rm -rf /tmp/* /var/cache/debconf/*-old /var/lib/apt/lists/* \
        /var/lib/dpkg/*-old /var/log/*log /var/log/apt/* /var/tmp/*

RUN echo "Installing vagrant ${VAGRANT_VERSION}..." \
 && VAGRANT_DEB="vagrant_${VAGRANT_VERSION}_x86_64.deb" \
 && curl -sLo /tmp/$VAGRANT_DEB https://releases.hashicorp.com/vagrant/$VAGRANT_VERSION/$VAGRANT_DEB \
 && dpkg -i /tmp/$VAGRANT_DEB && rm -rf /tmp/$VAGRANT_DEB \
 && vagrant plugin install vagrant-cosmic

# Monkey patch Berkshelf to print errors returned by Chef-Guard, this can be removed when
# https://github.com/berkshelf/berkshelf/pull/1827 has been merged.
RUN echo "Monkey patching Berkshelf (see https://github.com/berkshelf/berkshelf/pull/1827)..." \
 && sed -i -e 's/Berkshelf.formatter.skipping(cookbook, connection)/Berkshelf.formatter.skipping(cookbook, connection)\nrescue Net::HTTPClientException => e\nputs e.response.body/' \
        /opt/chef-workstation/embedded/lib/ruby/gems/*/gems/berkshelf-*/lib/berkshelf/uploader.rb

# Create additional directories for Chef workflow
RUN mkdir -p /environments

# Setup entrypoint
COPY docker-entrypoint.sh /usr/bin
ENTRYPOINT ["docker-entrypoint.sh"]
