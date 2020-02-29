#!/usr/bin/bash
az group deployment create --resource-group "rsg-sea-ubot-westus" \
  --template-file "custom-arm.json" \
  --parameters appId="" \
  appSecret="" \
  botId="ubot-bot" \
  newWebAppName="ubot-bot-webapp" \
  existingAppServicePlan="ubot-bot" \
  appServicePlanLocation="centralus" \
  --name "ubot-bot-webapp"
