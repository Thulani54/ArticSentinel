"""Recover only ArticSentinel's queue; preserve compromised container/volume.
Run on the server with sudo python3. Does not send mail or delete queue evidence.
"""
import json, os, secrets, shutil, subprocess
from pathlib import Path
root = Path('/home/vmrvsnyo/exvr')
backup = Path('/home/vmrvsnyo/.codex-backups/email-incident-20261108')
backup.mkdir(parents=True, exist_ok=True, mode=0o700)
compose = root / 'docker-compose.yml'
env = root / '.env'
for path in [compose, env]:
    target = backup / (path.name + '.before')
    if not target.exists():
        shutil.copy2(path, target)
        target.chmod(0o600)
def docker(*args):
    return subprocess.check_output(['docker', *args], text=True)
for name, args in [
    ('redis-inspect.json', ['inspect', 'exvr_redis']),
    ('redis-processes.txt', ['top', 'exvr_redis']),
    ('redis-diff.txt', ['diff', 'exvr_redis']),
]:
    path = backup / name
    if not path.exists():
        path.write_text(docker(*args))
        path.chmod(0o600)
image = json.loads(docker('image', 'inspect', 'redis:7-alpine'))[0]
digest = next(d for d in image['RepoDigests'] if d.startswith('redis@sha256:'))
text = compose.read_text()
start = text.index('  redis:\n')
end = text.index('  # Django web application', start)
assert '6379:6379' in text[start:end]
assert text.count('CELERY_BROKER_URL=redis://redis:6379/0') == 3
assert text.count('CELERY_RESULT_BACKEND=redis://redis:6379/0') == 3
secure = root / '.redis-recovery'
secure.mkdir(mode=0o700, exist_ok=True)
password = secrets.token_hex(32)
(secure / 'redis.conf').write_text(
    'bind 0.0.0.0\nprotected-mode yes\nport 6379\n'
    'appendonly yes\ndir /data\n'
    'requirepass ' + password + '\n'
    'rename-command CONFIG ""\nrename-command MODULE ""\n'
    'rename-command DEBUG ""\nrename-command REPLICAOF ""\n'
    'rename-command SLAVEOF ""\n'
)
(secure / 'redis.conf').chmod(0o644)
block = """  # Recovered queue. The old exvr_redis container/volume remain quarantined.
  redis_queue:
    image: IMAGE_DIGEST
    container_name: exvr_redis_recovered
    restart: unless-stopped
    user: "999:999"
    read_only: true
    cap_drop: [ALL]
    # Snap Docker rejects exec with no-new-privileges; use non-root and no capabilities.
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]
    volumes:
      - ./.redis-recovery/redis.conf:/usr/local/etc/redis/redis.conf:ro
      - redis_recovered_data:/data
    tmpfs:
      - /tmp:noexec,nosuid,size=16m
    healthcheck:
      test: ["CMD-SHELL", "REDISCLI_AUTH=$$(sed -n 's/^requirepass //p' /usr/local/etc/redis/redis.conf) redis-cli ping | grep -q PONG"]
      interval: 15s
      timeout: 5s
      retries: 3
    networks:
      exvr_network:
        aliases: [redis]

"""
text = text[:start] + block.replace('IMAGE_DIGEST', digest) + text[end:]
text = text.replace('CELERY_BROKER_URL=redis://redis:6379/0', 'CELERY_BROKER_URL=${ARTIC_REDIS_BROKER_URL:?Set ARTIC_REDIS_BROKER_URL}')
text = text.replace('CELERY_RESULT_BACKEND=redis://redis:6379/0', 'CELERY_RESULT_BACKEND=${ARTIC_REDIS_BROKER_URL:?Set ARTIC_REDIS_BROKER_URL}')
text = text.replace('      - redis\n', '      - redis_queue\n')
assert '\n  redis_data:' in text
text = text.replace('\n  redis_data:', '\n  redis_recovered_data:\n  redis_data:', 1)
env_text = env.read_text()
assert 'ARTIC_REDIS_BROKER_URL=' not in env_text
env.write_text(env_text.rstrip() + '\nARTIC_REDIS_BROKER_URL=redis://:' + password + '@redis:6379/0\n')
env.chmod(0o600)
compose.write_text(text)
subprocess.run(['docker','compose','config','--quiet'],cwd=root,check=True)
print('Saved evidence and configuration backup:', backup)
print('Configured authenticated private queue using', digest)

