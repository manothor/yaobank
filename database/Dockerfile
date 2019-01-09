FROM quay.io/coreos/etcd:v3.3.7

# Copy in the default data files and set group/user permissions.
COPY default.etcd /default.etcd
RUN chgrp -R 0 /default.etcd && \
    chmod -R g=u /default.etcd
