#!/bin/sh
set -eu

write_wizard <<'WIZARD'
[
  {
    "step_title": "${welcomeTitle}",
    "activate_v2": "{ var step = arguments[0]; var terms = step.getComponent('wizard_agree_terms'); step.syncTermsNext = function () { step.owner.getButton('next').setDisabled(terms.checked !== true); }; terms.on('check', step.syncTermsNext); step.termsNextTimer = setTimeout(step.syncTermsNext, 0); }",
    "deactivate_v2": "{ var step = arguments[0]; clearTimeout(step.termsNextTimer); step.getComponent('wizard_agree_terms').un('check', step.syncTermsNext); }",
    "items": [
      {
        "desc": "${beforeTerms}<a href=\"${termsUrl}\" target=\"_blank\" rel=\"noopener noreferrer\">${termsTitle}</a>${networkAdvice}"
      },
      {
        "type": "multiselect",
        "subitems": [
          {
            "key": "wizard_agree_terms",
            "desc": "${agreeTerms}",
            "defaultValue": false
          }
        ]
      }
    ]
  },
  {
    "step_title": "${settingsTitle}",
    "items": [
      {
        "type": "textfield",
        "desc": "${portAdvice}",
        "subitems": [
          {
            "key": "DP_APP_SERVER_PORT",
            "desc": "${portLabel}",
            "defaultValue": "8086",
            "validator": {
              "allowBlank": false,
              "regex": {
                "expr": "/^[1-9][0-9]{3,4}$/",
                "errorText": "${portRangeError}"
              }
            }
          },
          {
            "key": "DP_INIT_USERNAME",
            "desc": "${usernameLabel}",
            "defaultValue": "admin",
            "validator": {
              "allowBlank": true,
              "regex": {
                "expr": "/^[a-zA-Z0-9_]*$/",
                "errorText": "${usernameFormatError}"
              }
            }
          }
        ]
      },
      {
        "type": "password",
        "desc": "${passwordAdvice}",
        "subitems": [
          {
            "key": "DP_INIT_PASSWORD",
            "desc": "${passwordLabel}",
            "defaultValue": "",
            "validator": {
              "allowBlank": true,
              "minLength": 6
            }
          }
        ]
      }
    ]
  },
  {
    "step_title": "${dockerTitle}",
    "items": [
      {
        "desc": "${dockerAdvice}<a href='${helpUrl}' target='_blank' rel='noopener noreferrer'>${helpLink}</a><br><span style='font-size:12px;color:#666'>${logHint}</span>"
      },
      {
        "desc": "<label for='wizard_docker_socket_command'><strong>${socketLabel}</strong></label><textarea id='wizard_docker_socket_command' readonly rows='2' style='display:block;width:100%;box-sizing:border-box'>sudo sh -c 'chgrp dpanel /var/run/docker.sock &amp;&amp; chmod 660 /var/run/docker.sock'</textarea>"
      },
      {
        "desc": "<label for='wizard_docker_user_command'><strong>${userLabel}</strong></label><br>${userAdvice}<textarea id='wizard_docker_user_command' readonly rows='2' style='display:block;width:100%;box-sizing:border-box'>sudo synogroup --memberadd dpanel \"$(id -un)\"</textarea>"
      }
    ]
  }
]
WIZARD
