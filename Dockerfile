FROM --platform=linux/arm64/v8 node:14.16.0-buster as builder

ARG VERSION=6.8.0
ENV CY_VERSION=$VERSION

# Install build dependencies
RUN apt-get update && \
  apt-get install --no-install-recommends -y \
  chromium \
  libgtk2.0-0 \
  libgtk-3-0 \
  libnotify-dev \
  libgconf-2-4 \
  libgbm-dev \
  libnss3 \
  libxss1 \
  libasound2 \
  libxtst6 \
  xauth \
  xvfb \
  # clean up
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium"

# build cypress binary
RUN git clone https://github.com/cypress-io/cypress.git --depth 1 --branch v${CY_VERSION}

WORKDIR /cypress

RUN yarn

# copy fixed path calculating
COPY fixPath.js /cypress/node_modules/app-builder-lib/out/platformPackager.js

RUN yarn binary-build --version ${CY_VERSION}

WORKDIR /

FROM --platform=linux/arm64 node:14.16.0-buster-slim

ARG VERSION=6.8.0

ENV TERM=xterm \
    NPM_CONFIG_LOGLEVEL=warn \
    QT_X11_NO_MITSHM=1 \
    _X11_NO_MITSHM=1 \
    _MITSHM=0 \
    CYPRESS_INSTALL_BINARY=0 \
    CYPRESS_CACHE_FOLDER=/root/.cache/Cypress \
    CY_VERSION=$VERSION

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    libgtk2.0-0 \
    libgtk-3-0 \
    libnotify-dev \
    libgconf-2-4 \
    libgbm-dev \
    libnss3 \
    libxss1 \
    libasound2 \
    libxtst6 \
    xauth \
    xvfb \
    # clean up
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    # https://github.com/cypress-io/cypress/issues/4351#issuecomment-559489091
    echo 'pcm.!default {\n type hw\n card 0\n}\n\nctl.!default {\n type hw\n card 0\n}' > /root/.asoundrc

# Copy cypress binary from intermediate container
COPY --from=builder /cypress/build/linux-unpacked /root/.cache/Cypress/6.9.1/Cypress

RUN npm install -g cypress@6.9.1 && \ 
    cypress verify