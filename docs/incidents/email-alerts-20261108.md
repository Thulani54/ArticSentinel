# Email and scale-alert investigation — 8 November 2026

## Findings
- The ArticSentinel worker repeatedly failed to connect to Redis (connection refused). Docker showed the container as running, but its process list contained cryptocurrency miners and shell persistence rather than a Redis server.
- The original Redis service published port 6379 on the host. This was an exposure; the investigation did not establish the initial intrusion method or prove that compromise was limited to this container.
- Seven-day communication logs contained 34 failed Gmail emails, 16 sent emails to switchfive.tech and one failed email to that domain. The recent Gmail failures recorded SMTP 535 incorrect authentication data. These entries predated queue recovery.
- A login-only probe using the current configured mailbox succeeded over TLS when validating the presented certificate against its actual hosting name, arno.aserv.co.za. No message was submitted. Standard verification using mail.articsentinel.com failed hostname validation. The existing application mail implementation relaxes certificate verification; it was not changed in this investigation.
- Web and worker mail settings matched at comparison time. This does not explain definitively why earlier authentication failed.
- An active device_offline email template and gas_level_alert template exist. No active device_online email template exists; the sender skips channels with no matching template.
- Connection-alert checking uses a three-minute recent-reading window, while the API online helper defaults to the device offline_timeout (10 minutes on inspected scales). Status emails also have a 30-minute per-recipient/device/template cooldown.
- The notification sender uses stored status transitions, while MQTT updates online status itself. A broader transition/recovery audit is still needed before promising an email on every reconnect.

## Containment and recovery
- Paused the compromised exvr_redis container, disabled its restart policy and disconnected it from all Docker networks, then terminated it. Verified exited status, zero network attachments and restart=no. Preserved its container, original volume and restricted incident evidence rather than reusing or deleting them.
- Evidence/configuration backup on server: /home/vmrvsnyo/.codex-backups/email-incident-20261108. Contains before-state Compose/environment, inspect, processes and filesystem diff. Access restricted; do not commit this directory.
- Pulled the official Redis 7 Alpine image and pinned the replacement to digest sha256:c5d34a98396a4775e223c74e929162c35c5a2182901ba26b50ade939941ce14b.
- Added redis_queue / exvr_redis_recovered with a new volume, random authentication secret, no published host ports, a non-root user, dropped Linux capabilities, read-only root filesystem, a health check and disabled Redis configuration/module/replication commands.
- Retained the Redis DNS alias for application compatibility. Updated all three application broker/result-backend settings to use the authenticated queue URL, stored only in the server environment.
- The host's Snap Docker runtime rejected executable startup with no-new-privileges. A minimal trusted-image probe reproduced this; that option was omitted while retaining the other restrictions.
- Recreated only the web, worker, scheduler and replacement queue services. No database or device telemetry was removed. The compromised queue contents were not replayed.
- Implementation record: backend/operations/recover_queue_20261108.py. One-time installer; do not rerun on an already recovered deployment.

## Verification
- New Redis container running and healthy; no published ports.
- Unauthenticated Redis PING rejected with NOAUTH; authenticated PING succeeded.
- No host listeners remained on Redis port 6379 or Docker API ports 2375/2376 at the final server check.
- Celery control ping returned pong.
- Scheduled gas-level, device-threshold and device-alert tasks completed. Device-alert sweep processed 13 devices with zero errors.
- UAT website returned HTTP 200.
- No new communication log entries during the short post-recovery observation window. No manual test email was sent, and inbox receipt has not been verified.

## Remaining work / limits
- Full server incident investigation and appropriate credential review are still necessary. Queue recovery is not proof that the host or other services are clean.
- Correct the SMTP hostname/certificate configuration and investigate historical 535 errors if they recur.
- Configure and test recovery notifications deliberately, including MQTT/status transition ownership, timeout consistency and cooldown behavior.
- Previously missed notifications were not bulk-replayed; replaying stale alerts could mislead recipients.
- The earlier request for mailbox-control-panel access was diagnostic. Current authentication passed, so a password reset is not presently established as necessary.


## Follow-up investigation and repair (8 November, evening)

### Confirmed security evidence
- The stopped broker was Redis **7.4.7**, from a November 2025 image. Its Docker container had been created in February 2026; that creation date is not an intrusion date.
- `.syscache`/agent file change times in the Redis volume start at **2026-11-06 06:50 UTC / 08:50 SAST**. The preserved `.sc-node.log` records scans of other public Redis endpoints beginning at 06:50:09 UTC. The container was therefore involved in scanning as well as cryptocurrency mining.
- XMRig 6.22.0 and 6.26.0 artifacts were present. The earliest retained timestamp in one miner log is 6 November 07:31 UTC, with entries through 8 November 17:19 UTC. Docker daemon logs independently show mining-pool DNS requests on 6 November.
- Evidence supports malicious activity for **at least about 58 hours 29 minutes** before the original pause at 8 November 19:19 SAST. It does not establish the exact initial entry time. An older March file modification date belongs to a downloaded binary and is not evidence of a March intrusion.
- The likely entry route is the exposed, unauthenticated Redis service running a version with later-known RCE fixes missing. The original Compose setup published 6379 publicly without an authentication configuration. The available logs do not prove a specific CVE or identify the initial attacking client.
- Official Redis release notes describe RCE fixes after 7.4.7 in May, July and August 2026: https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisce-7.4-release-notes/ . Redis recommends keeping the service inaccessible to untrusted clients: https://redis.io/docs/latest/operate/oss_and_stack/management/security/ .
- Retained SSH authentication logs from approximately 13 October onward show successful logins using the same existing ED25519 key; no different successful SSH key or successful password login was found in those files. One cloud/VPN-looking source address (79.127.218.37) was raised with the owner for identification. This is not evidence that address is malicious, nor proof that the known key was never misused.
- Host/root SSH authorized-key modification dates predate the incident. Reviewed custom cron/systemd entries were identifiable application/maintenance services with older modification dates. A targeted current-process scan found no remaining matching miner/agent process names after containment; this was not a full host-integrity examination.
- UFW was inactive and several database/application ports were bound to all interfaces. Their external reachability and business dependencies have not all been established. Do not blanket-close them without mapping dependencies; restrict them as part of host hardening.
- The quarantined Redis container was not privileged and had only its data-volume mount, without the Docker socket or host filesystem mounted. This narrows the observed foothold but does not rule out lateral movement, data access or host compromise.

### Watchdog correction and evidence preservation
- The existing cron watchdog restarted the stopped original container at 19:28 SAST despite its Docker restart policy being disabled. The container remained disconnected from Docker networks. It was running the original Redis binary after that restart; the restored container start is not a new confirmed mining event.
- Added an explicit exclusion for `exvr_redis` and `exvr_redis_quarantined_*` to the watchdog, renamed the original to **exvr_redis_quarantined_20261108**, and stopped it again. Subsequent checks confirmed `exited`, zero network attachments and restart policy `no`.
- Preserved the Redis volume as a restricted archive on the server: `/home/vmrvsnyo/.codex-backups/email-incident-20261108/redis-volume-evidence.tar.gz`.
- Archive SHA-256: `43c0280ad301684f16245ce225e04a12fafdd1831966b9d5fb937b957bff68d3`.
- Preserved entrypoint, Redis binary, miner log, filesystem diff, container/image inspection, Docker events and a container-log extract. No malware was executed during analysis.
- Clean replacement verified as **Redis 7.4.12**, healthy and authenticated, with no host port binding. It uses a new data volume; old queued contents were not replayed.

### Email repairs deployed
- Replaced the certificate-bypassing email backend with authenticated STARTTLS using the default trusted CA chain. The connection still goes to `mail.articsentinel.com`; TLS explicitly verifies the hosting certificate identity `arno.aserv.co.za`. A future certificate/hosting-name change will fail closed and requires configuration review.
- Alerts, maintenance reminders and enhanced analytics report attachments now use the shared Django email backend. Removed their unauthenticated port-25 fallbacks. Report attachments and maintenance headers are retained.
- Added durable scale connection state and delivery records, independent of MQTT's `is_online` writes. Legacy gas status mutation no longer erases recovery transitions or automatically disables gas monitoring.
- Added the `device_online` email template and a one-minute polling job. The new recovery channel is scoped to gas scales. Four active scales received silent initial baselines; rollout itself did not email the fleet.
- Offline evaluation uses each scale's `offline_timeout` (currently 10 minutes on inspected scales). Once offline is observed, fresh telemetry produces a recovery event. Very brief interruptions under that timeout do not produce an offline/recovery email pair.
- Email opt-ins, active accounts, primary/secondary business membership, address deduplication and access rechecks apply. Successful notifications have a 30-minute same-state cooldown. Failed attempts retry up to five times with backoff; stale, superseded or revoked deliveries are not sent. No claim of crash-proof exactly-once SMTP delivery is made.
- 20 isolated tests passed. A real PostgreSQL transaction exercised installed offline/recovery/template/log code for three recipients in each direction, with SMTP mocked and all mutations rolled back. Django system checks passed; migrations applied; web/worker/scheduler restarted.
- Worker logs confirmed successful one-minute scale checks and delivery sweeps at 19:49, 19:50 and 19:51 SAST. Final quarantine verification still showed exited, zero networks and restart=no after multiple watchdog intervals.
- Source/backup locations: `backend/email_reliability/` locally and `/home/vmrvsnyo/.codex-backups/email-repair-20261108` on the host. Local raw source snapshots under `tmp/email-repair-20261108` may contain legacy embedded credentials and must not be committed.

### Explicitly requested test email
- Sent through the actual Celery worker and verified SMTP backend to **thulanik544@gmail.com**, as explicitly requested by the user.
- Subject: **ArticSentinel email delivery test - 8 November 2026**.
- Celery task: `89f38118-2228-4840-965b-ca65bbaf6edb`; communication log **7369** reported **sent** (SMTP accepted).
- Confirmed receipt through the connected Gmail account: message `1a1bc47b63e0828f`, received **8 November at 19:49:33 SAST**, labelled **INBOX**, UNREAD, IMPORTANT and CATEGORY_PERSONAL (not Spam). This verifies actual inbox receipt, not just SMTP acceptance.
- Gmail's Authentication-Results reports **SPF pass, DKIM pass and DMARC pass**. Received headers show authenticated TLS submission from the application server to the hosting mail service and onward TLS delivery to Gmail. The message was left unread; no Gmail labels were changed.
