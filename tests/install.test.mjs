// Offline installer contract: change only the network transport. The files
// pass through the actual SHA checks, gzip/exec, staging and symlink switch.
import assert from 'node:assert/strict'
import {test} from 'node:test'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import {spawnSync} from 'node:child_process'
import {gzipSync} from 'node:zlib'
import {createHash} from 'node:crypto'
const script=new URL('../install.sh',import.meta.url)
test('install, reinstall, corrupt package, unmanaged command, unpublished release',()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'public-installer-')),bin=path.join(root,'bin'),home=path.join(root,'user home')
 try{
  fs.mkdirSync(bin);fs.mkdirSync(home)
  const stub=(name,s)=>fs.writeFileSync(path.join(bin,name),'#!/bin/sh\nset -eu\n'+s+'\n',{mode:0o700})
  stub('uname',"echo 'Darwin arm64'")
  stub('curl',`while [ "$#" -gt 3 ]; do shift; done\ncp "$FIXTURE/\${1##*/}" "$3"`)
 const version='v0.1.0';fs.writeFileSync(path.join(root,'stable'),version)
  const launcher=gzipSync(Buffer.from('#!/bin/sh\n[ "$1 $2" = "install meltemia" ] && cmp "$3" "$FIXTURE/host.zip"\n')),bundle=Buffer.from('fixture release bytes')
  const lines=[]
  for(const [name,b,role] of [['desk.gz',launcher,'launcher'],['host.zip',bundle,'host']]){
   fs.writeFileSync(path.join(root,name),b);lines.push(`${role}-darwin-arm64\t${createHash('sha256').update(b).digest('hex')}\thttps://example.test/${name}`)
  }
  fs.writeFileSync(path.join(root,'files.tsv'),lines.join('\n'))
  const env={...process.env,HOME:home,FIXTURE:root,PATH:bin+':'+process.env.PATH},run=(...args)=>spawnSync('sh',[script.pathname,...args],{env,encoding:'utf8'})
  assert.equal(run().status,0);assert.equal(run('--version',version).status,0)
  const link=path.join(home,'.local/bin/cortivar'),before=fs.readFileSync(link);fs.writeFileSync(path.join(root,'host.zip'),'bad')
  assert.notEqual(run().status,0);assert.deepEqual(fs.readFileSync(link),before)
  fs.unlinkSync(link);fs.writeFileSync(link,'other');assert.notEqual(run('--role','launcher').status,0);assert.equal(fs.readFileSync(link,'utf8'),'other')
  fs.writeFileSync(path.join(root,'stable'),'unpublished');assert.match(run().stderr,/No stable release/)
 }finally{fs.rmSync(root,{recursive:true})}
})

test('latest resolves one stable catalog; exact pins bypass it and never fall back', (t) => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cortivar-versions-'))
  t.after(() => fs.rmSync(tmp, {recursive: true}))
  const bin = path.join(tmp, 'bin'), link = path.join(tmp, '.local/bin/cortivar')
  const origin = 'https://raw.githubusercontent.com/Cortivar/platform-docs/main'
  fs.mkdirSync(bin)
  fs.writeFileSync(path.join(bin, 'uname'), "#!/bin/sh\necho 'Darwin arm64'\n", {mode: 0o700})
  fs.writeFileSync(path.join(bin, 'curl'), `#!/bin/sh
set -eu
while [ "$#" -gt 3 ]; do shift; done
printf '%s\\n' "$1" >>"$HOME/requests"
cp "$HOME/site/\${1#https://}" "$3"
`, {mode: 0o700})
  function put(url, bytes) {
    const p = path.join(tmp, 'site', url.slice('https://'.length))
    fs.mkdirSync(path.dirname(p), {recursive: true}); fs.writeFileSync(p, bytes)
  }
  const stable = `${origin}/channels/stable`
  const catalog = v => `${origin}/versions/${v}/files.tsv`
  const asset = v => `https://test.invalid/releases/${v}/launcher.gz`
  for (const v of ['v1.9.9', 'v1.10.0', 'v2.0.0-rc.1']) {
    const bytes = gzipSync(Buffer.from(v))
    put(asset(v), bytes)
    put(catalog(v), `launcher-darwin-arm64\t${createHash('sha256').update(bytes).digest('hex')}\t${asset(v)}\n`)
  }
  const log = path.join(tmp,'requests')
  function check(args, requests, version, success = true) {
    fs.writeFileSync(log,'')
    const p = spawnSync('sh', [script.pathname,'--role','launcher',...args], {
      encoding:'utf8', env:{...process.env,HOME:tmp,PATH:bin+':'+process.env.PATH}
    })
    assert.equal(p.status === 0, success, p.stderr)
    assert.deepEqual(fs.readFileSync(log,'utf8').split('\n').filter(Boolean), requests)
    assert.equal(fs.readFileSync(link,'utf8'), version)
  }
  put(stable,'v1.9.9\n')
  check([], [stable,catalog('v1.9.9'),asset('v1.9.9')],'v1.9.9')
  put(stable,'v1.10.0\n')
  check(['--version','latest'], [stable,catalog('v1.10.0'),asset('v1.10.0')],'v1.10.0')
  check(['--version','1.9.9'], [catalog('v1.9.9'),asset('v1.9.9')],'v1.9.9')
  const rc='v2.0.0-rc.1'
  put(stable,rc)
  check([], [stable], 'v1.9.9', false)
  check(['--version',rc], [catalog(rc),asset(rc)], rc)
  check(['--version','v9.9.9'],[catalog('v9.9.9')],rc,false)
  check(['--version','1.x'],[],rc,false)
})
