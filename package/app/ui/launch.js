function getPackagePort() {
  const port = window.dpanelPort;
  if (!Number.isInteger(port) || port < 1024 || port > 65535) {
    throw new Error(message('portUnavailable'));
  }
  return port;
}

async function getSynoToken() {
  const data = await queryDSM('/webapi/entry.cgi?api=SYNO.API.Auth&version=6&method=token');
  return typeof data?.synotoken === 'string' ? data.synotoken : '';
}

async function getProxyRuleList(port, token) {
  const data = await queryDSM('/webapi/entry.cgi/SYNO.Core.AppPortal.ReverseProxy?api=SYNO.Core.AppPortal.ReverseProxy&version=1&method=list',
    token ? { 'X-SYNO-TOKEN': token } : {});
  if (!Array.isArray(data?.entries)) throw new Error(message('proxyRuleListMissing'));
  return data.entries.filter(rule => rule?.backend?.protocol === 0 &&
    ['127.0.0.1', 'localhost'].includes(rule.backend.fqdn) && rule.backend.port === port);
}

function getPanelEntry(ruleList, port) {
  const protocol = location.protocol === 'https:' ? 1 : 0;
  const matchRuleList = ruleList.filter(rule => rule.frontend?.protocol === protocol);
  const front = matchRuleList[matchRuleList.length - 1]?.frontend;
  if (!front) {
    // A proxy for the other protocol does not authorize falling back to direct HTTP.
    if (ruleList.length > 0 || window.dpanelHost === '127.0.0.1') {
      const error = new Error(message('proxyRuleRequired'));
      error.code = 'proxyRuleRequired';
      error.port = port;
      throw error;
    }
    if (window.dpanelHost !== '0.0.0.0') throw new Error(message('listenAddressUnavailable'));
    const url = new URL('/dpanel/ui', location.href);
    url.protocol = 'http:';
    url.port = String(port);
    return url;
  }
  if (!Number.isInteger(front.port) || front.port < 1 || front.port > 65535) {
    throw new Error(message('invalidProxyPort'));
  }
  const host = [null, '', '*'].includes(front.fqdn) ? location.hostname : front.fqdn;
  // Accept a hostname or bracketed IPv6 literal, not credentials, a path or a second port.
  if (typeof host !== 'string' || !/^(?:[\p{L}\p{N}._-]+|\[[0-9a-f:.]+\])$/iu.test(host)) {
    throw new Error(message('invalidProxyHost'));
  }
  return new URL(`${location.protocol}//${host}:${front.port}/dpanel/ui`);
}
