FROM public.ecr.aws/primaassicurazioni/elixir:1.19.1-1-bookworm

USER root
WORKDIR /drone/src
RUN mkdir -p /drone/src

ENTRYPOINT ["/bin/bash", "-c"]
CMD []
