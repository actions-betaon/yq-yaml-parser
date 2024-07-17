# Set the base image to use for subsequent instructions
FROM mikefarah/yq:4.44.2-githubaction

# Copy any source file(s) required for the action
COPY entrypoint.sh /entrypoint.sh

# Configure the container to be run as an executable
ENTRYPOINT ["/entrypoint.sh"]
