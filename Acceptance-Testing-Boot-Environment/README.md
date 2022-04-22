# iPXE Boot Environment

## Running with Docker
1. Build the image: `docker build -t acceptance-testing-boot-environment:latest .`.
1. Run the API: `docker run -ti -p 3001:3001 acceptance-testing-boot-environment`.
1. The REST API can then be queried on `localhost:3001`.