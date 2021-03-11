FROM public.ecr.aws/prima/elixir:1.11.2-1

USER root
WORKDIR /drone/src
RUN mkdir -p /drone/src

ENTRYPOINT ["/bin/bash", "-c"]
CMD []
