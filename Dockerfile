FROM public.ecr.aws/prima/elixir:1.14.2-5

USER root
WORKDIR /drone/src
RUN mkdir -p /drone/src

ENTRYPOINT ["/bin/bash", "-c"]
CMD []
