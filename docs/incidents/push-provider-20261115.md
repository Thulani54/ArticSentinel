# Push provider dependency repair — 15 November 2026

## Findings

The monitoring emails reflected two different conditions:

- `push-provider` had failed since 8 November at 17:25 UTC. The deployed
  application images could not import `google.auth`, although the source
  requirements already included `google-auth>=2.40,<3`. Restarting services had
  reused images without the dependency.
- `ai-provider` reported a DNS resolution error starting 14 November at 23:57
  UTC. It recovered before this intervention, at 15 November 05:22 UTC
  (07:22 SAST), according to the persisted monitoring state. Live DNS/TCP checks
  succeeded; an unauthenticated HTTPS request to the models endpoint returned
  HTTP 401. This confirms reachability, not successful model inference. The
  next scheduled check at 06:12 UTC reproduced the DNS failure, so the early
  successful checks did not establish a lasting recovery.
- Both web and worker configuration already used the corrected email sender
  display name `Artic Sentinel`. Previously delivered messages retain their
  original headers.

## Repair

On `/home/vmrvsnyo/exvr`, added an import check immediately after dependency
installation in the Dockerfile. Builds now fail if the Google service-account
or request transport imports are unavailable. Added `.secrets/`, Redis recovery
configuration, backups and MQTT credentials/certificates to `.dockerignore`.
The existing runtime source mount supplies the private FCM credential file.

Rebuilt web, Celery worker and Celery beat images. Each new image passed the
Google imports and reported `google-auth 2.62.2`. Django's configuration check
reported no issues. Recreated only those three application services.

Previous Dockerfile, requirements and ignore file are backed up privately at
`/home/vmrvsnyo/.codex-backups/provider-repair-20261115/`, with the build log.
Previous application images are retained under each image's
`before-provider-repair-20261115` tag. Credentials and server settings must not
be copied into this repository.

## Intermittent DNS investigation

Docker forwarded external DNS through the host's systemd-resolved stub, whose
only upstream was `8.8.8.8`. A direct AAAA lookup for `api.deepseek.com` to that
upstream timed out while A records resolved. Subsequent queries succeeded,
confirming intermittent behavior rather than a consistently missing domain.
The exact cause of the upstream timeout was not established.

Direct A/AAAA comparisons against `1.1.1.1` and `1.0.0.1` passed all three rounds
for each resolver. Configured these redundant upstreams in Compose for web,
worker and beat only, retaining Docker service discovery. The host resolver and
other applications were not changed. Compose backup:
`docker-compose.before-dns.yml` in the same private backup directory.

References: [Docker DNS behavior](https://docs.docker.com/engine/network/#dns-services)
and [Cloudflare resolver addresses](https://developers.cloudflare.com/1.1.1.1/ip-addresses/).

## Verification

- The new worker successfully refreshed the configured FCM service-account
  credentials: `FCM credentials valid`.
- The AI reachability check returned healthy.
- Celery inspect ping returned one responding worker.
- The public monitoring endpoint responded with its expected HTTP 403 without
  authentication.
- The recovered Redis container remained running and healthy; the quarantined
  container remained stopped with zero network attachments.

- FCM HTTP v1 accepted a `validate_only: true` notification request with HTTP
  200. Used a validation topic because the requested account had no enabled
  Android installation registered. This verifies provider access and payload
  validation without delivery; it does not demonstrate notification display
  on a phone. No test message was sent.

- The normal scheduled check recorded push-provider recovery at
  `2026-11-15 06:12:26 UTC` (08:12 SAST), with zero consecutive failures. The same
  run reproduced the intermittent AI DNS error, leading to the DNS change above.

After the DNS change:

- All three services showed the intended two DNS upstreams and were running.
- A database query and Redis service-name lookup succeeded.
- FCM credential refresh still succeeded.
- Eight separate HTTPS requests to DeepSeek, spaced ten seconds apart and
  spanning the observed 60-second address TTL, all returned the expected
  unauthenticated HTTP 401 in 0.41–0.46 seconds, with no DNS or TLS failures.
- The normal scheduled monitor recorded AI recovery at
  `2026-11-15 06:17:31 UTC` (08:17 SAST). At that check both AI and push were
  healthy with zero consecutive failures.

This verifies recovery during the observation window; it does not establish
the root cause of the upstream DNS interruption or guarantee future third-party
availability. Existing scheduled monitoring remains enabled. No manual recovery
state updates or real test notifications were used.
