const targets = document.querySelector('#targets'), log = document.querySelector('#log'), result = document.querySelector('#result');
async function refresh() {
  const data = await (await fetch('/api/status')).json();
  targets.value = data.targets.join('\n');
  log.textContent = data.log.join('\n') || 'No activity yet.';
}
document.querySelector('#save').onclick = async () => {
  const response = await fetch('/api/targets', {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({targets: targets.value.split('\n').map(x => x.trim()).filter(Boolean)})});
  result.textContent = response.ok ? 'Saved.' : (await response.json()).error;
  if (response.ok) refresh();
};
refresh();
