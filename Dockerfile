FROM public.ecr.aws/primaassicurazioni/elixir:1.17.3-bookworm

USER root
WORKDIR /drone/src
RUN mkdir -p /drone/src

ENTRYPOINT ["/bin/bash", "-c"]
CMD []
