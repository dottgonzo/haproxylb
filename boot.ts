import fs from 'fs'

let data =
  'global \n\
  user haproxy \n\
  group haproxy \n\
  tune.ssl.default-dh-param 2048 \n\
\n\
defaults \n\
  log global \n\
  mode http \n\
  timeout connect 5000 \n\
  timeout client 50000 \n\
  timeout server 50000 \n\n'

const backends = process.env.BACKENDS.split(',')
const services = process.env.SERVICES.split(',').map(m => {
  return {
    port: m.split(':')[0],
    targetPort: m.split(':')[1],
    mode: m.split(':')[2],
    proxy_protocol: m.split(':')[3] && m.split(':')[3].split(';').includes('proxy_protocol')
  }
})
for (const s of services) {
  data += 'frontend ' + s.port + '_front\n'
  data += '  bind *:' + s.port + '\n'
  if (s.mode === 'tcp') data += '  option tcplog \n'
  data += '  mode ' + s.mode + '\n'
  data += '  use_backend ' + s.port + '_back\n\n'
}
for (const s of services) {
  data += 'backend ' + s.port + '_back\n'
  data += '  balance roundrobin\n'
  data += '  mode ' + s.mode + '\n'
  if (s.mode === 'tcp') data += '  option tcp-check \n'

  for (const b of backends) {
    data += '  server ' + b.replace(/\./g, '_') + ' ' + b + ':' + s.targetPort + ' check\n'
  }
  data += '\n'
}

fs.writeFileSync(process.env.HAPROXY_CONFIG_PATH || '/usr/local/etc/haproxy/haproxy.cfg', data)
