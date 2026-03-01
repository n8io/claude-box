FROM node:lts-slim

# ── Layer 1: Core system packages ──────────────────────────────────────────────
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    zsh \
    curl \
    wget \
    gnupg \
    ca-certificates \
    ripgrep \
    jq \
    python3 \
    python3-pip \
  && chsh -s /bin/zsh node \
  && rm -rf /var/lib/apt/lists/*

# ── Layer 2: Terraform ─────────────────────────────────────────────────────────
RUN wget -O- https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(. /etc/os-release && echo $VERSION_CODENAME) main" \
    > /etc/apt/sources.list.d/hashicorp.list \
  && apt-get update && apt-get install -y --no-install-recommends terraform \
  && rm -rf /var/lib/apt/lists/*

# ── Layer 3: Playwright (chromium only, must run as root for system deps) ──────
RUN npm install -g playwright \
  && playwright install chromium --with-deps

# ── Layers 4-8: User-level tools (run as node) ────────────────────────────────
USER node
ENV HOME=/home/node
ENV PATH="/home/node/.local/bin:$PATH"

# Layer 4: Claude Code (native installer)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Layer 5: oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Layer 6: zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions \
      ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
  && git clone https://github.com/zsh-users/zsh-syntax-highlighting \
      ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Layer 7: Configure .zshrc (theme + plugins)
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="russell"/' $HOME/.zshrc \
  && sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' $HOME/.zshrc

# Layer 8: NVM + LTS Node
ENV NVM_DIR=$HOME/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
  && . $NVM_DIR/nvm.sh \
  && nvm install --lts \
  && nvm alias default lts/*

WORKDIR /

ENTRYPOINT ["claude"]
