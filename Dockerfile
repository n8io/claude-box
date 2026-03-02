FROM node:lts-slim

# ── Layer 1: Core system packages ──────────────────────────────────────────────
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gosu \
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

# ── Layer 4: Jira CLI ──────────────────────────────────────────────────────────
RUN JIRA_LATEST=$(curl -fsSL https://api.github.com/repos/ankitpokhrel/jira-cli/releases/latest \
      | jq -r '.tag_name') \
  && case "$(dpkg --print-architecture)" in \
      amd64) JIRA_ARCH=x86_64 ;; \
      arm64) JIRA_ARCH=arm64 ;; \
      *) echo "Unsupported arch: $(dpkg --print-architecture)" && exit 1 ;; \
    esac \
  && curl -fsSL "https://github.com/ankitpokhrel/jira-cli/releases/download/${JIRA_LATEST}/jira_${JIRA_LATEST#v}_linux_${JIRA_ARCH}.tar.gz" \
      -o /tmp/jira.tar.gz \
  && echo "jira-cli ${JIRA_LATEST} (${JIRA_ARCH}) SHA256: $(sha256sum /tmp/jira.tar.gz)" \
  && tar -xzf /tmp/jira.tar.gz --wildcards '*/bin/jira' --strip-components=2 -C /usr/local/bin \
  && rm /tmp/jira.tar.gz

# ── Layers 5-9: User-level tools (run as node) ────────────────────────────────
USER node
ENV HOME=/home/node
ENV PATH="/home/node/.local/bin:$PATH"

# Layer 5: NVM + LTS Node (slowest changing)
ENV NVM_DIR=$HOME/.nvm
RUN NVM_LATEST=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
      | jq -r '.tag_name') \
  && curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST}/install.sh" \
      -o /tmp/nvm-install.sh \
  && echo "nvm ${NVM_LATEST} install.sh SHA256: $(sha256sum /tmp/nvm-install.sh)" \
  && bash /tmp/nvm-install.sh \
  && rm /tmp/nvm-install.sh \
  && . $NVM_DIR/nvm.sh \
  && nvm install --lts \
  && nvm alias default lts/*

# Layer 6: oh-my-zsh
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
      -o /tmp/omz-install.sh \
  && echo "oh-my-zsh install.sh SHA256: $(sha256sum /tmp/omz-install.sh)" \
  && sh /tmp/omz-install.sh --unattended \
  && rm /tmp/omz-install.sh

# Layer 7: zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions \
      ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
  && git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
      log -1 --format="zsh-autosuggestions commit: %H" \
  && git clone https://github.com/zsh-users/zsh-syntax-highlighting \
      ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
  && git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
      log -1 --format="zsh-syntax-highlighting commit: %H"

# Layer 8: Configure .zshrc (theme + plugins)
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="russell"/' $HOME/.zshrc \
  && sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' $HOME/.zshrc

# Layer 9: Claude Code (fastest changing)
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh \
  && echo "claude install.sh SHA256: $(sha256sum /tmp/claude-install.sh)" \
  && bash /tmp/claude-install.sh \
  && rm /tmp/claude-install.sh

WORKDIR /

# Switch back to root so the entrypoint can fix SSH socket permissions
# before dropping back to the node user via gosu.
USER root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
