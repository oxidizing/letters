FROM hadolint/hadolint:latest-alpine AS hadolint
FROM ocaml/opam:debian-11-ocaml-4.12

USER root

# copy hadolint
COPY --from=hadolint /bin/hadolint /bin/hadolint

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV SIHL_ENV development

# install packages
RUN apt-get update -q && apt-get install -yqq --no-install-recommends \
  # development dependencies
  inotify-tools \
  zsh \
  m4 \
  wget \
  #
  # build dependencies (would also be installed by opam depext)
  gcc \
  libev-dev \
  libgmp-dev \
  libssl-dev \
  pkg-config \
  #
  # cleanup installations
  && apt-get autoremove -y \
  && apt-get clean all

# add timezone
RUN ln -fs /usr/share/zoneinfo/Europe/Zurich /etc/localtime

# WTF: https://github.com/mirage/ocaml-cohttp/issues/675
RUN bash -c 'echo "http		80/tcp	www		# WorldWideWeb HTTP" >> /etc/services' \
  && bash -c 'echo "https		443/tcp	www		# WorldWideWeb HTTPS" >> /etc/services'

USER opam

# install oh-my-zsh
RUN zsh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  && cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc \
  && sed -i "/^plugins=/c\plugins=(git dotenv)" ~/.zshrc \
  #
  # link make to devcontainer makefile
  && echo 'alias make="make -f /workspace/.devcontainer/Makefile"' >> ~/.zshrc

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
