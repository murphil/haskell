FROM nnurphy/io

ENV STACK_ROOT=/opt/stack

RUN set -ex \
  ; apt-get update \
  ; apt-get install -y --no-install-recommends \
        libicu-dev libffi-dev libgmp-dev zlib1g-dev \
        libncurses-dev libtinfo-dev libblas-dev liblapack-dev \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN set -ex \
  ; mkdir -p ${STACK_ROOT} && mkdir -p ${HOME}/.cabal \
  ; curl -sSL https://get.haskellstack.org/ | sh \
  ; stack config set system-ghc --global false \
  ; stack config set install-ghc --global true \
  ; stack update && stack setup \
  # JuicyPixels xhtml criterion weigh alex happy
  # cassava diagrams \
  ; stack install -j1 --no-interleaved-output \
      ghcid haskell-dap ghci-dap haskell-debug-adapter \
      optparse-applicative shelly process unix \
      time clock hpc pretty filepath directory zlib \
      array hashtables dlist binary bytestring text \
      containers hashable unordered-containers vector \
      deepseq call-stack primitive ghc-prim \
      template-haskell aeson yaml taggy mustache \
      flow lens recursion-schemes fixed mtl fgl \
      parsers megaparsec Earley boomerang \
      free extensible-effects extensible-exceptions freer \
      bound unbound-generics transformers transformers-compat \
      syb uniplate singletons dimensional \
      monad-par parallel async stm classy-prelude \
      persistent memory cryptonite \
      mwc-random MonadRandom random \
      monad-logger monad-journal \
      regex-base regex-posix regex-compat \
      pipes conduit machines \
      http-conduit wreq HTTP html websockets multipart\
      servant scotty wai network network-uri warp \
      QuickCheck smallcheck hspec \
      hmatrix linear statistics ad integration arithmoi \
  #; mkdir -p ${STACK_ROOT}/global-project \
  # 设置全局 stack resolver, 避免运行时重新安装 lts
  #; sed -i "s/^\(resolver:\).*$/\1 ${STACKAGE_VERSION}/g" ${STACK_ROOT}/global-project/stack.yaml \
  ; rm -rf ${STACK_ROOT}/programs/x86_64-linux/*.tar.xz \
  ; rm -rf ${STACK_ROOT}/pantry/hackage/* \
  ; stack install flow \
  ; stack new hello rio && rm -rf hello \
  ; stack new hello && rm -rf hello \
  ; yq e --inplace ".allow-different-user=true" ${STACK_ROOT}/config.yaml \
  ; for x in config.yaml \
             templates \
             stack.sqlite3.pantry-write-lock \
             pantry/pantry.sqlite3.pantry-write-lock \
             snapshots/x86_64-linux-tinfo6 \
  ; do chmod 777 ${STACK_ROOT}/$x; done \
  ; chmod -R 777 ${STACK_ROOT}/global-project

RUN set -ex \
  ; mkdir -p /opt/language-server/haskell \
  ; hls_version=$(curl -sSL -H "Accept: application/vnd.github.v3+json"  https://api.github.com/repos/haskell/haskell-language-server/releases | jq -r '.[0].tag_name') \
  ; ghc_version=$(stack ghc -- --version | grep -oP 'version \K([0-9\.]+)') \
  ; curl -sSL https://github.com/haskell/haskell-language-server/releases/download/${hls_version}/haskell-language-server-wrapper-Linux.gz | gzip -d > /opt/language-server/haskell/haskell-language-server-wrapper \
  ; curl -sSL https://github.com/haskell/haskell-language-server/releases/download/${hls_version}/haskell-language-server-Linux-${ghc_version}.gz | gzip -d > /opt/language-server/haskell/haskell-language-server-${ghc_version} \
  ; chmod +x /opt/language-server/haskell/* \
  ; for l in /opt/language-server/haskell/*; do ln -fs $l /usr/local/bin; done

COPY ghci /root/.ghci
COPY config.tuna.yaml ${STACK_ROOT}/config.tuna.yaml
