FROM ubuntu:focal

RUN mkdir /build
WORKDIR /build
COPY . .

RUN cd /build && \
    apt-get update && \
    apt-get -y install git python3 python3-pip shellcheck && \
    pip3 install pre-commit && \
    pre-commit install
RUN ls -l && pre-commit --version

CMD ["printenv"]
