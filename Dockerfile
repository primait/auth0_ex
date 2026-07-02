FROM public.ecr.aws/primaassicurazioni/elixir:1.20.2-bookworm

USER root
WORKDIR /drone/src
RUN mkdir -p /drone/src

ENTRYPOINT ["/bin/bash", "-c"]
CMD []
