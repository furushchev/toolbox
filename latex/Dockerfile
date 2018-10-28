FROM ubuntu:18.04
MAINTAINER Yuki Furuta <furushchev@jsk.imi.i.u-tokyo.ac.jp>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -q -qq -y && apt-get install -q -qq -y --no-install-recommends \
ghostscript \
git \
ssh \
texlive-fonts-recommended \
texlive-lang-japanese \
texlive-latex-base \
texlive-latex-extra \
texlive-science \
texlive-plain-generic \
latexmk \
&& rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
WORKDIR /workspace
CMD ["/entrypoint.sh"]
