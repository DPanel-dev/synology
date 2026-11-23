const port = window.dpanelPort;
if (Number.isInteger(port) && port >= 1024 && port <= 65535) {
  const url = new URL('/dpanel/ui', window.location.href);
  url.protocol = 'http:';
  url.port = String(port);
  const link = document.getElementById('open');
  link.href = url.href;
  link.textContent = `打开 DPanel（${url.host}）`;
  link.hidden = false;
  document.getElementById('missing').hidden = true;
  window.location.replace(url.href);
}
