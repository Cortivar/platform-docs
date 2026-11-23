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
  const version='v0.1.0-alpha.1';fs.writeFileSync(path.join(root,'stable'),version)
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
  fs.writeFileSync(path.join(root,'stable'),'unpublished');assert.match(run().stderr,/No tested full-platform release/)
 }finally{fs.rmSync(root,{recursive:true})}
})
