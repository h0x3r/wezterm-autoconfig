#!/bin/bash

# version: 1.1.0

# 检查是否已配置网络代理
check_proxy() {
  # env | grep -i proxy
  if [ -n "$http_proxy" ] || [ -n "$https_proxy" ]; then
    echo "检测到已有代理配置。"
    return 0
  else
    # 询问是否需要配置网络代理
    echo "未检测到zsh代理，是否需要配置网络代理（通常只发生在中国大陆地区）？(yes/no)"
    read -r self_config
    case "$self_config" in
      [Yy]* ) return 1 ;;  # 用户选择设置代理
      [Nn]* ) echo "将在不使用代理的情况下继续执行。"
              return 0 ;;  # 用户选择不设置代理
      * ) echo "无效输入，请输入 yes 或 no。"
          check_proxy ;;   # 递归调用直到获得有效输入
    esac
  fi
}

# 配置代理
set_proxy() {
  echo "是否需要此脚本协助配置网络代理？(yes/no)"
  read -r self_config
  case "$self_config" in
    [Yy]* )
      echo "请输入 HTTP 代理地址 (默认: http://127.0.0.1:7890):"
      read -r http_proxy_input
      echo "请输入 HTTPS 代理地址 (默认: http://127.0.0.1:7890):"
      read -r https_proxy_input
      http_proxy=${http_proxy_input:-http://127.0.0.1:7890}
      https_proxy=${https_proxy_input:-http://127.0.0.1:7890}

      export http_proxy
      export https_proxy

      echo "已设置临时代理。"
      ;;
    [Nn]* )
      echo "请自行配置网络代理后再执行此脚本。"
      exit 0 ;;
    * )
      echo "无效输入，请输入 yes 或 no。"
      set_proxy ;;  # 递归调用直到获得有效输入
  esac
}

# 检查并安装brew
check_brew() {
  if ! command -v brew &> /dev/null; then
    echo "未检测到 Homebrew，是否安装？(yes/no)"
    read -r install_brew
    case "$install_brew" in
      [Yy]* ) /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" ;;
      [Nn]* ) echo "请自行安装 Homebrew 后再执行此脚本。"
              exit 0 ;;
      * ) echo "无效输入，请输入 yes 或 no。"
          check_brew ;;  # 递归调用直到获得有效输入
    esac
  else
    echo "Homebrew 已安装。"
  fi
}

# 安装 wezterm
install_wezterm() {
  if brew list --cask | grep -q "wezterm"; then
      echo "WezTerm 已安装。"
    else
      brew install --cask wezterm
      echo "WezTerm 已安装。"
    fi
}

# 配置 wezterm
setup_wezterm() {
  # 如果 wezterm.lua 已存在，则不再覆盖
  if [ -f ~/.config/wezterm/wezterm.lua ]; then
    echo "WezTerm 配置已存在，跳过配置。"
  else
    mkdir -p ~/.config/wezterm
    cat <<EOF > ~/.config/wezterm/wezterm.lua
-- Path: ~/.config/wezterm/wezterm.lua
-- github.com/riverify
-- This is a configuration file for wezterm, a GPU-accelerated terminal emulator for modern workflows.

local wezterm = require("wezterm")

config = wezterm.config_builder()

config = {
    automatically_reload_config = true,
    enable_tab_bar = true,
    hide_tab_bar_if_only_one_tab = true,    -- Hide the tab bar when there is only one tab
    window_close_confirmation = "NeverPrompt",
    window_decorations = "TITLE | RESIZE", -- disable the title bar but enable the resizable border
    font = wezterm.font("JetBrains Mono", { weight = "Bold" }),
    font_size = 13,
    color_scheme = "Nord (Gogh)",
    default_cursor_style = 'BlinkingBlock',
    macos_window_background_blur = 25, -- Enable window background blur on macOS
    background = {
        {
            source = {
                Color = "#301934", -- dark purple
            },
            width = "100%",
            height = "100%",
            opacity = 0.85,
        },
    },
    window_padding = {
        left = 3,
        right = 3,
        top = 0,
        bottom = 0,
    },
    initial_rows = 50,
    initial_cols = 100,
}

return config
EOF
    echo "WezTerm 配置完成。"
  fi
}

# 检查是否已安装 Starship
install_starship() {
  if brew list | grep -q "starship"; then
    echo "Starship 已安装。"
  else
    echo "正在检测并安装 Starship..."
    brew install starship
    echo "Starship 已安装。"
  fi
}

setup_starship() {
  if [ -f ~/.config/starship.toml ]; then
    echo "Starship 配置已存在，跳过配置。"
  else
    mkdir -p ~/.config
    # 使用更精确的 EOF 保证格式正确写入
    cat > ~/.config/starship.toml <<'EOF'
format = """
$directory\
$git_branch\
$git_status\
$fill\
$python\
$lua\
$nodejs\
$golang\
$haskell\
$rust\
$ruby\
$aws\
$docker_context\
$jobs\
$cmd_duration\
$line_break\
$character"""

add_newline = true
palette = "nord"

[directory]
style = 'bold fg:dark_blue'
format = '[$path ]($style)'
truncation_length = 3
truncation_symbol = '…/'
truncate_to_repo = false

[git_branch]
style = 'fg:green'
symbol = ' '
format = '[on](white) [$symbol$branch ]($style)'

[git_status]
style = 'fg:red'
format = '([$all_status$ahead_behind]($style) )'

[fill]
symbol = ' '

[python]
style = 'teal'
symbol = ' '
format = '[${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'
pyenv_version_name = true
pyenv_prefix = ''

[lua]
format = '[$symbol($version )]($style)'
symbol = ''

[nodejs]
style = 'blue'
symbol = ' '

[golang]
style = 'blue'
symbol = ' '

[haskell]
style = 'blue'
symbol = ' '

[rust]
style = 'orange'
symbol = ' '

[ruby]
style = 'blue'
symbol = ' '

[package]
symbol = '󰏗 '

[aws]
symbol = ' '
style = 'yellow'
format = '[$symbol($profile )(\[$duration\] )]($style)'

[docker_context]
symbol = ' '
style = 'fg:#06969A'
format = '[$symbol]($style) $path'
detect_files = ['docker-compose.yml', 'docker-compose.yaml', 'Dockerfile']
detect_extensions = ['Dockerfile']

[jobs]
symbol = ' '
style = 'red'
number_threshold = 1
format = '[$symbol]($style)'

[cmd_duration]
min_time = 500
style = 'fg:gray'
format = '[$duration]($style)'

[palettes.nord]
dark_blue = '#5E81AC'
blue = '#81A1C1'
teal = '#88C0D0'
red = '#a61725'  # #BF616A
orange = '#D08770'
green = '#85c270'  # #A3BE8C
yellow = '#EBCB8B'
purple = '#B48EAD'
gray = '#434C5E'
black = '#2E3440'
white='#D8DEE9'

[palettes.onedark]
dark_blue='#61afef'
blue='#56b6c2'
red='#e06c75'
green='#98c379'
purple='#c678dd'
cyan='#56b6c2'
orange='#be5046'
yellow='#e5c07b'
gray='#828997'
white ='#abb2bf'
black='#2c323c'
EOF
    echo "Starship 样式配置完成。"
  fi
}

# 安装并配置 zsh 插件
setup_zsh() {

  echo "正在检测并安装 zsh 插件。"

  if ! brew list | grep -q "zsh-syntax-highlighting"; then
    brew install zsh-syntax-highlighting
  fi

  if ! brew list | grep -q "zsh-autosuggestions"; then
    brew install zsh-autosuggestions
  fi

  echo "安装完成，正在检查 .zshrc 配置。"

  # 插入 Starship 配置，并添加空行
  if ! grep -q "starship init zsh" ~/.zshrc; then
    cat <<EOF >> ~/.zshrc

# Starship
eval "\$(starship init zsh)"
EOF
  fi

  # 插入 zsh-syntax-highlighting 配置，并添加空行
  if ! grep -q "zsh-syntax-highlighting" ~/.zshrc; then
    cat <<EOF >> ~/.zshrc

# Activate the syntax highlighting
source \$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
EOF
  fi

  # 插入 zsh-autosuggestions 配置，并添加空行
  if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
    cat <<EOF >> ~/.zshrc

# Activate the autosuggestions
source \$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
EOF
  fi

  # 插入代理配置，并添加空行
  if ! grep -q "export http_proxy" ~/.zshrc; then
    cat <<EOF >> ~/.zshrc

# Proxy (Only for China Mainland)
export http_proxy="$http_proxy"
export https_proxy="$https_proxy"
EOF
  fi

  # 插入 alias 配置，并添加空行
  if ! grep -q "alias ll" ~/.zshrc; then
    cat <<EOF >> ~/.zshrc

# Aliases
alias ll='ls -al'
alias shutdown='sudo shutdown -h now'
EOF
  fi

  # 插入问候函数
  if ! grep -q "greet_user" ~/.zshrc; then
    cat <<'EOF' >> ~/.zshrc

# 每次进入终端时显示问候信息和电脑状态
greet_user() {
    # 获取当前时间
    current_time=$(date +"%Y-%m-%d %H:%M")
    echo "Welcome back, $USER"
    echo "time: $current_time"
}

# 调用问候函数
greet_user
EOF
  fi

  echo ".zshrc 配置完成。"
}




# 主脚本流程
main() {
  check_proxy || set_proxy
  check_brew
  install_wezterm
  setup_wezterm
  install_starship
  setup_starship
  setup_zsh

  echo "所有配置完成，即刻体验WezTerm吧！"
}

main
