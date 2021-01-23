import fs from 'fs'

let data =
  'global \n\
  log /dev/log local0 \n\
  log /dev/log local1 notice \n\
  stats timeout 30s \n\
  user root \n\
  group root \n\
  daemon \n\
\n\
defaults \n\
  log global \n\
  mode http \n\
  option httplog \n\
  option dontlognull \n\
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
  data += '  mode ' + s.mode + '\n' + (s.mode === 'tcp' ? '  option tcp-check \n' : '')
  data += '  default_backend ' + s.port + '_back\n\n'
}
for (const s of services) {
  data += 'backend ' + s.port + '_back\n'
  data += '  balance roundrobin\n'
  for (const b of backends) {
    data += '  server ' + b.replace(/\./g, '_') + ' ' + b + ':' + s.targetPort + ' check\n'
  }
  data += '\n'
}

fs.writeFileSync(process.env.HAPROXY_CONFIG_PATH || '/usr/local/etc/haproxy/haproxy.cfg', data)
