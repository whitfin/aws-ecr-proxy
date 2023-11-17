# AWS ECR Docker Proxy

[![Build Status](https://img.shields.io/github/actions/workflow/status/whitfin/aws-ecr-docker-proxy/ci.yml?branch=main)](https://github.com/whitfin/aws-ecr-docker-proxy/actions) ![Docker Image Version](https://img.shields.io/docker/v/whitfin/aws-ecr-docker-proxy)

The AWS ECR Docker Proxy is a very simple Nginx proxy to allow forwarding requests through to
Amazon ECR. Responses are cached locally to optimize throughput, and credentials can be
handled by either key/secret pairs or AWS instance roles.

This project was originally based on the existing [aws-ecr-http-proxy](https://github.com/Lotto24/aws-ecr-http-proxy)
repository. As that project has not had any major changes in a few years and appears to no longer
be maintained (at least for now), this repository was separated out as some of the planned changes
will be incompatible moving forward. The original forked code will live on the `legacy` branch as
a point of reference, and the `main` branch will carry the new line of changes. Obviously major
credit goes to the original author(s)!

## Configuration:

The AWS ECR Proxy is packaged into a Docker container. As such, all configuration is
done by providing environment variables at container startup. The following values
are currently supported:

| Name                    | Description                                                                 | Default              | Required                                     |
| ----------------------- | --------------------------------------------------------------------------- | -------------------- | -------------------------------------------- |
| AWS_REGION              | The AWS Region for AWS ECR login                                            | None                 | Yes                                          |
| AWS_ACCESS_KEY_ID       | The AWS Access Key for AWS ECR login                                        | None                 | Yes, if not using `AWS_INSTANCE_AUTH=true` |
| AWS_SECRET_ACCESS_KEY   | The AWS Secret Access Key for AWS ECR login                                 | None                 | Yes, if not using `AWS_INSTANCE_AUTH=true` |
| AWS_INSTANCE_AUTH       | Whether or not to enable IAM based authentication                           |
false                | No                                         |
| PROXY_CACHE_KEY         | The key used in Nginx to cache response context                             | $uri                 | No                                           |
| PROXY_CACHE_LIMIT       | The maximum size the Nginx cache can grow to                                | 64gb                 | No                                           |
| PROXY_DNS_RESOLVER      | The DNS server used by the proxy to resolve hosts                           | 8.8.8.8 (Google DNS) | No                                           |
| PROXY_ECR_ENDPOINT      | The endpoint of the AWS ECR repository to proxy requests to                 | None                 | Yes                                          |
| PROXY_NAMESPACE_PATTERN | The pattern used to include or exclude from the images available on AWS ECR | `.*`                 | No                                           |
| PROXY_PORT              | The port that the Nginx proxy will listen for traffic on                    | 5000                 | No                                           |
| PROXY_SSL_KEY           | The path to the TLS key to use when enabling SSL traffic                    | None                 | No                                           |
| PROXY_SSL_CERTIFICATE   | The path to the TLS certificate to use when enabling SSL traffic            | None                 | No                                           |

## Example Usage

Below is a minimal example of running the proxy using an AWS key/secret pair. These
are the minimal set of parameters you need to supply if using the defaults for all
other values.

```sh
docker run \
  -d \
  --net host \
  --name docker-registry-proxy \
  -e "AWS_REGION=${AWS_DEFAULT_REGION}" \
  -e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
  -e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
  -e "PROXY_ECR_ENDPOINT=https://XXXXXXXXXX.dkr.ecr.eu-central-1.amazonaws.com" \
  -v /tmp/cache:/cache \
  whitfin/aws-ecr-proxy:latest
```

If you are going to use IAM roles instead, you can omit the key/secret pair and set
`AWS_INSTANCE_AUTH=true`. Assuming your container is running on localhost, you can
now access your ECR images:

```sh
docker pull localhost:5000/my-ecr-image
```

The layers will be cached in Nginx to avoid re-pulling them from ECR repeatedly,
in theory saving bandwidth and reducing latency.

## Namespace Exclusion

It's possible you have many images in AWS ECR, and you only wish to proxy through
to some of them. For this case you can set `PROXY_NAMESPACE_PATTERN`, which accepts
a regular expression to match namepaces to allow.

For example, if I have 3 images in ECR (`image1`, `image2` and `image3`), here is
how I can exclude the second image easily:

```sh
PROXY_NAMESPACE_PATTERN="(image1|image3)"
```

Please note that this parameter is used to configure routes in Nginx, so your pattern
has to be compatible with Nginx's matching. As such, this option should be considered
experimental for the time being, but if it works for you it will be safe to use.

## TLS/SSL Support

By default the proxy uses plain HTTP, so if you're running the proxy on a remote host
Docker will probably complain. You can either enable SSL/TLS by providing a key and
certificate, or you can mark your proxy registry as insecure in the Docker configuration.

If you're using this proxy as a sidecar service running on localhost, there is no need
to worry about TLS/SSL support. This could be the case for something like Nexus OSS.

If you'd like more details here, there is some information on this in the official
[Docker documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#insecure-registries).
