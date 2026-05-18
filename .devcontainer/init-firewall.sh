#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [ "$(id -u)" -ne 0 ]; then
  echo "init-firewall.sh must run as root because it configures iptables." >&2
  exit 1
fi

command -v iptables >/dev/null
command -v ipset >/dev/null
command -v dig >/dev/null

# Preserve Docker's embedded DNS NAT rules before flushing tables.
DOCKER_DNS_RULES="$(iptables-save -t nat | grep '127\.0\.0\.11' || true)"

iptables -F || true
iptables -X || true
iptables -t nat -F || true
iptables -t nat -X || true
iptables -t mangle -F || true
iptables -t mangle -X || true
ipset destroy allowed-domains 2>/dev/null || true

if [ -n "$DOCKER_DNS_RULES" ]; then
  iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
  iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
  while IFS= read -r rule; do
    [ -n "$rule" ] && iptables -t nat $rule || true
  done <<< "$DOCKER_DNS_RULES"
fi

# Allow loopback and DNS.
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --sport 53 -j ACCEPT

# Allow SSH. This does not mount host SSH keys; it only allows outbound SSH traffic.
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

ipset create allowed-domains hash:ip

base_domains=(
  api.anthropic.com
  claude.ai
  platform.claude.com
  downloads.claude.ai
  storage.googleapis.com
  raw.githubusercontent.com
  github.com
  api.github.com
  codeload.github.com
  objects.githubusercontent.com
  registry.npmjs.org
  marketplace.visualstudio.com
  vscode.blob.core.windows.net
  update.code.visualstudio.com
)

extra_domains=()
if [ -n "${ALLOW_EXTRA_DOMAINS:-}" ]; then
  # shellcheck disable=SC2206
  extra_domains=(${ALLOW_EXTRA_DOMAINS})
fi

for domain in "${base_domains[@]}" "${extra_domains[@]}"; do
  [ -z "$domain" ] && continue
  echo "Allowing domain: $domain"
  mapfile -t ips < <(dig +short A "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true)
  if [ "${#ips[@]}" -eq 0 ]; then
    echo "WARNING: no A records resolved for $domain; continuing" >&2
    continue
  fi
  for ip in "${ips[@]}"; do
    ipset add allowed-domains "$ip" 2>/dev/null || true
  done
done

# Permit traffic between container and Docker host network for editor/port-forwarding behavior.
HOST_IP="$(ip route | awk '/default/ {print $3; exit}')"
if [ -n "$HOST_IP" ]; then
  HOST_NETWORK="$(echo "$HOST_IP" | sed 's/\.[0-9]*$/.0\/24/')"
  iptables -A INPUT -s "$HOST_NETWORK" -j ACCEPT
  iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT
fi

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

echo "Container firewall enabled. Outbound traffic is limited to DNS, SSH, host network, and allowed domains."
