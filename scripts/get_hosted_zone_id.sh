#!/bin/bash
# Script to get Route53 hosted zone ID for a domain

DOMAIN=${1:-thekloudwiz.com}

echo "🔍 Looking up hosted zone for domain: $DOMAIN"
echo ""

ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name "$DOMAIN" \
  --query "HostedZones[?Name=='${DOMAIN}.'].Id" \
  --output text | cut -d'/' -f3)

if [ -n "$ZONE_ID" ]; then
  echo "✅ Found hosted zone!"
  echo ""
  echo "Hosted Zone ID: $ZONE_ID"
  echo ""
  echo "Add this to your environments/*.tfvars:"
  echo "hosted_zone_id = \"$ZONE_ID\""
else
  echo "❌ No hosted zone found for $DOMAIN"
  echo ""
  echo "To create a hosted zone:"
  echo "aws route53 create-hosted-zone --name $DOMAIN --caller-reference $(date +%s)"
fi
