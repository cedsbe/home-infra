records_public = {
  "ghiot.be_a" = {
    zone_name = "ghiot.be"
    name      = "ghiot.be"
    type      = "A"
    comment   = "Main A record for ghiot.be domain"
    content   = "213.186.33.48"
    ttl       = 1 # automatic
    proxied   = true
  }

  "autodiscover.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "autodiscover.ghiot.be"
    type      = "CNAME"
    comment   = "Public DNS record for Outlook autodiscover"
    content   = "autodiscover.outlook.com"
    proxied   = false
  }

  "calendar.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "calendar.ghiot.be"
    type      = "CNAME"
    comment   = "Google Calendar integration"
    content   = "ghs.google.com"
    proxied   = false
  }

  "docs.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "docs.ghiot.be"
    type      = "CNAME"
    comment   = "Google Docs integration"
    content   = "ghs.google.com"
    proxied   = false
  }

  "ftp.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "ftp.ghiot.be"
    type      = "CNAME"
    comment   = "FTP service hosted on OVH"
    content   = "ftp.1000gp.ovh.net"
    proxied   = false
  }

  "ftp2.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "ftp2.ghiot.be"
    type      = "CNAME"
    comment   = "Anonymous FTP service on OVH"
    content   = "anonymous.ftp.ovh.net"
    proxied   = false
  }

  "mail.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "mail.ghiot.be"
    type      = "CNAME"
    comment   = "Mail subdomain for Google services"
    content   = "ghs.google.com"
    proxied   = false
  }

  "ovhmo166055-selector1._domainkey.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "ovhmo166055-selector1._domainkey.ghiot.be"
    type      = "CNAME"
    comment   = "OVH DKIM selector 1 for email authentication"
    content   = "ovhmo166055-selector1._domainkey.1639548.pq.dkim.mail.ovh.net"
    proxied   = false
  }

  "ovhmo166055-selector2._domainkey.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "ovhmo166055-selector2._domainkey.ghiot.be"
    type      = "CNAME"
    comment   = "OVH DKIM selector 2 for email authentication"
    content   = "ovhmo166055-selector2._domainkey.1639547.pq.dkim.mail.ovh.net"
    proxied   = false
  }

  "selector1._domainkey.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "selector1._domainkey.ghiot.be"
    type      = "CNAME"
    comment   = "Microsoft 365 DKIM selector 1"
    content   = "selector1-ghiot-be._domainkey.ghiotcedricgmail.onmicrosoft.com"
    proxied   = false
  }

  "selector2._domainkey.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "selector2._domainkey.ghiot.be"
    type      = "CNAME"
    comment   = "Microsoft 365 DKIM selector 2"
    content   = "selector2-ghiot-be._domainkey.ghiotcedricgmail.onmicrosoft.com"
    proxied   = false
  }

  "ghiot.be_txt_spf" = {
    zone_name = "ghiot.be"
    name      = "ghiot.be"
    type      = "TXT"
    comment   = "SPF record for ghiot.be"
    content   = "\"v=spf1 include:mx.ovh.com include:_spf.google.com include:spf.mailjet.com include:spf.protection.outlook.com ~all\""
    proxied   = false
  }

  "ghiot.be_txt_dmarc" = {
    zone_name = "ghiot.be"
    name      = "_dmarc.ghiot.be"
    type      = "TXT"
    comment   = "DMARC policy for email authentication"
    content   = "\"v=DMARC1; p=quarantine; rua=mailto:dmarc@ghiot.be\""
    proxied   = false
  }

  "ghiot.be_txt_ms_verification" = {
    zone_name = "ghiot.be"
    name      = "ghiot.be"
    type      = "TXT"
    comment   = "Microsoft domain verification"
    content   = "\"MS=ms85442441\""
    proxied   = false
  }

  "www.ghiot.be" = {
    zone_name = "ghiot.be"
    name      = "www.ghiot.be"
    type      = "CNAME"
    comment   = "WWW subdomain pointing to root domain"
    content   = "ghiot.be"
    ttl       = 1 # automatic
    proxied   = true
  }

  "ghiot.be_mx" = {
    zone_name = "ghiot.be"
    name      = "ghiot.be"
    type      = "MX"
    comment   = "Microsoft 365 mail exchange record"
    content   = "ghiot-be.mail.protection.outlook.com"
    priority  = 10
    proxied   = false
  }

  # ghiot.net zone records
  "ghiot.net_txt_spf" = {
    zone_name = "ghiot.net"
    name      = "ghiot.net"
    type      = "TXT"
    comment   = "SPF record for ghiot.net"
    content   = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\""
    proxied   = false
  }

  "ghiot.net_txt_dmarc" = {
    zone_name = "ghiot.net"
    name      = "_dmarc.ghiot.net"
    type      = "TXT"
    comment   = "DMARC policy for email authentication"
    content   = "\"v=DMARC1; p=none; rua=mailto:51ca84ce53474000a0ab0ddd657fa73f@dmarc-reports.cloudflare.net\""
    proxied   = false
  }
}
