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
    content   = "\"v=spf1 include:spf.mailjet.com include:spf.protection.outlook.com ~all\""
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
    comment   = "WWW subdomain pointing to Azure Static Web App"
    content   = "red-wave-089a8e303.2.azurestaticapps.net"
    ttl       = 1 # automatic
    proxied   = false
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
    content   = "\"v=spf1 include:spf.mailjet.com include:_spf.mx.cloudflare.net ~all\""
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
