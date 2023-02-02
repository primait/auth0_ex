FROM public.ecr.aws/prima/elixir:1.13.4-4

USER root
WORKDIR /drone/src
RUN mkdir -p /drone/src

ENTRYPOINT ["/bin/bash", "-c"]
CMD []
