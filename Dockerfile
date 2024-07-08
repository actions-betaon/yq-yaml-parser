# Set the base image to use for subsequent instructions
FROM mikefarah/yq:4.43.1

# Set the working directory inside the container
#WORKDIR /usr/src

# Copy any source file(s) required for the action
COPY entrypoint-wk.sh /entrypoint-wk.sh

USER root

# Configure the container to be run as an executable
ENTRYPOINT ["/entrypoint-wk.sh"]
