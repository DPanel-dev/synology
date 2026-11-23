const settings = window.dpanelConnection;
if (settings) {
  document.getElementById('destination').textContent = `http://127.0.0.1:${settings.port}`;
  let url;
  if (settings.publicOrigin) {
    try {
      const candidate = new URL('/dpanel/ui', settings.publicOrigin);
      if (candidate.protocol === 'https:') url = candidate;
    } catch {
      // Keep the setup instructions if the configured origin is unusable.
    }
  } else if (settings.direct) {
    url = new URL('/dpanel/ui', window.location.href);
    url.protocol = 'http:';
    url.port = settings.port;
  }
  if (url) {
    document.getElementById('open').href = url.href;
    document.getElementById('loopback').hidden = true;
    document.getElementById('direct').hidden = false;
  }
}
