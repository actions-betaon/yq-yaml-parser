# Set the base image to use for subsequent instructions
FROM mikefarah/yq:4.43.1

# Set the working directory inside the container
#WORKDIR /usr/src

RUN apk add --no-cache bash

# Copy any source file(s) required for the action
COPY entrypoint.sh /entrypoint.sh

USER root

# Configure the container to be run as an executable
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
