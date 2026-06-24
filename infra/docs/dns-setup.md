# DNS and DNSSEC Setup

This infrastructure creates a Google Cloud DNS zone for your subdomain (e.g., `myproject-dev.ciridae.app`) with DNSSEC enabled. The subdomain DNS is managed separately from the parent domain through NS record delegation. 
(in this example the parent domain is `ciridae.app` managed in the `int-provisioning-prod` GCP project)

## Prerequisites

- Access to your domain registrar or DNS provider for the parent domain
- Terraform deployed successfully (`terraform apply` completed)
- `gcloud` CLI installed and authenticated
- A DNS zone for your parent domain (this can be anywhere - Google Domains, Google Cloud DNS, Route53, etc.)

## Understanding the Setup

This infrastructure creates a DNS zone for your subdomain only (e.g., `myproject-dev.ciridae.app`), NOT the parent domain. The parent domain needs to delegate the subdomain to your Terraform-managed zone using NS records.

## Step 1: Get the Nameservers

After deploying the infrastructure, retrieve the Google Cloud DNS nameservers assigned to your subdomain zone:

```bash
cd infra/environments/dev
terraform output dns_nameservers
```

You'll see output like:
```
tolist([
  "ns-cloud-a1.googledomains.com.",
  "ns-cloud-a2.googledomains.com.",
  "ns-cloud-a3.googledomains.com.",
  "ns-cloud-a4.googledomains.com.",
])
```

**Important**: The letter in the nameservers (a, b, c, d, or e) is randomly assigned by Google. Always use the exact nameservers shown in your output.

## Step 2: Configure Subdomain Delegation

You need to add NS records in your parent domain to delegate the subdomain to Google Cloud DNS.

### If Parent Domain is in Google Cloud DNS:

```bash
# Replace these variables with your values
SUBDOMAIN="myproject-dev"

# Create NS records for subdomain delegation (all nameservers in one command)
gcloud dns --project=int-provisioning-prod record-sets create ${SUBDOMAIN}.ciridae.app. \
  --zone="ciridae-app" \
  --type="NS" \
  --ttl="300" \
  --rrdatas="NAMESERVER_1,NAMESERVER_2,NAMESERVER_3,NAMESERVER_4"
```

**Make sure you type out your subdomain correctly.**

**Note**: Replace `NAMESERVER_1`, `NAMESERVER_2`, `NAMESERVER_3`, and `NAMESERVER_4` with your actual nameservers from Step 1.

### If Parent Domain is elsewhere (SquareSpace, GoDaddy, Namecheap, etc.):

If you successfully ran the above command, **skip this step and proceed to Step 3**.

In your domain registrar's DNS management interface, add these records:
```
dev  NS  ns-cloud-a1.googledomains.com.
dev  NS  ns-cloud-a2.googledomains.com.
dev  NS  ns-cloud-a3.googledomains.com.
dev  NS  ns-cloud-a4.googledomains.com.
```

## Step 3: Get DNSSEC DS Record

Retrieve the DS record for DNSSEC:

```bash
terraform output ds_record_values
```

You'll see output like:
```
tolist([
  "21991 8 2 1330C2CEB422DE5AB00286288F7D74188F424EAFDDC0571B47CB5F097EE36193",
])
```

This DS record contains:
- **Key Tag**: 21991
- **Algorithm**: 8 (RSA/SHA-256)
- **Digest Type**: 2 (SHA-256)
- **Digest**: 1330C2CEB422DE5AB00286288F7D74188F424EAFDDC0571B47CB5F097EE36193

## Step 4: Add DS Record for DNSSEC

### If Parent Domain is in Google Cloud DNS:

```bash
# Get the DS record value
DS_RECORD=$(terraform output -json ds_record_values | jq -r '.[0]')

# Create DS record
gcloud dns --project=int-provisioning-prod record-sets create ${SUBDOMAIN}.ciridae.app. \
  --zone="ciridae-app" \
  --type="DS" \
  --ttl="300" \
  --rrdatas="$DS_RECORD"
```

**Make sure you type out your subdomain correctly.**

### If Parent Domain is elsewhere:

Again, if you successfully ran the above command, **skip this step and proceed to Step 5**.

In your domain registrar's DNSSEC or Advanced DNS settings:
1. Look for "DS records" or "DNSSEC" section
2. Add a DS record for the subdomain with:
   - **Subdomain**: dev (or your subdomain)
   - **Key Tag**: The first number from the DS record (e.g., 21991)
   - **Algorithm**: RSA/SHA-256 or RSASHA256
   - **Digest Type**: SHA-256
   - **Digest**: The long hex string (e.g., 1330C2CEB422...)

## Step 5: Verify DNS Configuration

After DNS propagation (can take up to 48 hours, usually much faster):

### Check nameserver delegation:
```bash
dig NS @8.8.8.8 ${SUBDOMAIN}.ciridae.app
```
(Checks against google's DNS, if the parent domain isn't managed by google's Cloud DNS, replace the @8.8.8.8 with your parent domain's nameservers or remove it altogether. ciridae.app is managed by google's Cloud DNS.)

Expected output:
```
; <<>> DiG 9.10.6 <<>> NS myproject-dev.ciridae.app
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 32029
;; flags: qr rd ra; QUERY: 1, ANSWER: 4, AUTHORITY: 0, ADDITIONAL: 9

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;myproject-dev.ciridae.app.     IN      NS

;; ANSWER SECTION:
myproject-dev.ciridae.app. 21600 IN    NS      ns-cloud-a1.googledomains.com.
myproject-dev.ciridae.app. 21600 IN    NS      ns-cloud-a2.googledomains.com.
myproject-dev.ciridae.app. 21600 IN    NS      ns-cloud-a3.googledomains.com.
myproject-dev.ciridae.app. 21600 IN    NS      ns-cloud-a4.googledomains.com.

;; ADDITIONAL SECTION:
ns-cloud-a1.googledomains.com. 326888 IN A     216.239.32.106
ns-cloud-a1.googledomains.com. 326899 IN AAAA  2001:4860:4802:32::6a
ns-cloud-a2.googledomains.com. 326943 IN A     216.239.34.106
ns-cloud-a2.googledomains.com. 326971 IN AAAA  2001:4860:4802:34::6a
ns-cloud-a3.googledomains.com. 326968 IN A     216.239.36.106
ns-cloud-a3.googledomains.com. 326970 IN AAAA  2001:4860:4802:36::6a
ns-cloud-a4.googledomains.com. 326945 IN A     216.239.38.106
ns-cloud-a4.googledomains.com. 326962 IN AAAA  2001:4860:4802:38::6a

;; Query time: 141 msec
;; SERVER: 192.168.50.1#53(192.168.50.1)
;; WHEN: Wed Jun 18 13:35:38 PDT 2025
;; MSG SIZE  rcvd: 350
```

**Key indicators of successful delegation:** Look for `status: NOERROR` in the header (confirms DNS query succeeded) and verify that the 4 nameservers in the ANSWER section match the ones from your `terraform output dns_nameservers`. The nameservers should all be `ns-cloud-[letter][number].googledomains.com` format. If you see different nameservers or get `NXDOMAIN` status, the delegation hasn't propagated yet or wasn't configured correctly.

### Check A record resolution:
```bash
dig +dnssec @8.8.8.8 ${SUBDOMAIN}.ciridae.app
```
(Here always keep the @8.8.8.8, it's checking against google's DNS.)

Expected output:
```
; <<>> DiG 9.10.6 <<>> A @8.8.8.8 myproject-dev.ciridae.app
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 50675
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;myproject-dev.ciridae.app.     IN      A

;; ANSWER SECTION:
myproject-dev.ciridae.app. 300 IN      A       35.244.170.121

;; Query time: 172 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
;; WHEN: Wed Jun 18 13:40:58 PDT 2025
;; MSG SIZE  rcvd: 72
```

**Key indicators of successful A record resolution:** Look for `status: NOERROR` and the `ad` flag (authenticated data, indicating DNSSEC validation). The ANSWER section should show your domain resolving to an IP address (typically your Google Cloud Load Balancer IP). If you get `NXDOMAIN` or no ANSWER section, DNS propagation may still be in progress.


### Check DNSSEC validation:
```bash
dig +dnssec @8.8.8.8 myproject-dev.ciridae.app
```

Expected output:
```
; <<>> DiG 9.10.6 <<>> +dnssec @8.8.8.8 myproject-dev.ciridae.app
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 45960
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags: do; udp: 512
;; QUESTION SECTION:
;myproject-dev.ciridae.app.     IN      A

;; ANSWER SECTION:
myproject-dev.ciridae.app. 300 IN      A       35.244.170.121
myproject-dev.ciridae.app. 300 IN      RRSIG   A 8 4 300 20250709204425 20250617204425 12345 myproject-dev.ciridae.app. AcTBVNP81UxxKo2pkihTLMCd+wqa2xfjT7NU9bJv2eN0zx2870rXiTrn HCLeUF9DjlyL9rWPXj8nqMuVjk9cvkS+U17f/rF+JKy5ett4+MbYhXkj JbfvgcaInnYNZAXMebkNwrkHFL15gAM93JC5SwBaVAU6y32Frtz+JDA+ /Jg=

;; Query time: 206 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
;; WHEN: Wed Jun 18 13:42:25 PDT 2025
;; MSG SIZE  rcvd: 320
```

**Key indicators of successful DNSSEC validation:** Look for the `ad` flag (authenticated data) in the flags section and `status: NOERROR`. The ANSWER section should contain both the A record and an RRSIG record (the DNSSEC signature). The `do` flag in the OPT PSEUDOSECTION confirms DNSSEC validation was requested. If you see `status: NXDOMAIN` but still have RRSIG records in the AUTHORITY section, DNSSEC is working but the domain may not be fully configured yet.


## Quick Reference Commands

```bash
# Get all DNS-related outputs at once
terraform output -json | jq '{
  nameservers: .dns_nameservers.value,
  ds_record: .ds_record_values.value[0],
  instructions: .ds_record_instructions.value
}'

# Get just the DS record in a formatted way
terraform output -raw ds_record_instructions

# Check DNS zone details in Google Cloud
gcloud dns managed-zones describe myproject-dev-dns --project=int-myproject-dev

# List all DNS records in the zone
gcloud dns record-sets list --zone=myproject-dev-dns --project=int-myproject-dev
```

## Troubleshooting

### DNS not resolving:
1. Verify NS records are correctly set in parent domain
2. Check that nameservers match exactly (including the letter prefix)
3. Wait for DNS propagation (use `dig @8.8.8.8` to check against Google's DNS)

### DNSSEC validation failing:
1. Ensure DS record is correctly entered in parent domain
2. Verify DNSSEC is enabled on both parent domain and subdomain
3. Check DS record format matches exactly
4. Use online DNSSEC debugger: https://dnsviz.net/

### Nameserver mismatch:
If you see different nameservers than expected (e.g., e1-e4 instead of a1-a4), the zone was likely recreated. Always use the nameservers from `terraform output dns_nameservers`.