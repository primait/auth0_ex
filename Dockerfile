FROM public.ecr.aws/prima/elixir:1.12.2-2

USER root
WORKDIR /drone/src
RUN mkdir -p /drone/src

ENTRYPOINT ["/bin/bash", "-c"]
CMD []
