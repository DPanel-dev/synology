#!/bin/sh
set -eu

{
cat <<'WIZARD'
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
WIZARD
# DSM submits registered fields; the inline radio group edits the proxy flag read by postinst.
tr '\n' ' ' <<'ACCESS'
    "activate_v2": "{
      var step = arguments[0], proxy = step.getComponent('wizard_listen_local');
      var row = document.getElementById('dpanel-access-row'), radio = row.querySelectorAll('input');
      var hint = document.getElementById('dpanel-access-hint');
      proxy.hide();
      function showAccess(local) {
        radio[0].checked = !local; radio[1].checked = local;
        hint.children[0].hidden = local; hint.children[1].hidden = !local;
      }
      showAccess(proxy.getValue() === true);
      row.onchange = function () { proxy.setValue(radio[1].checked); showAccess(radio[1].checked); };
      var password = step.getComponent('DP_INIT_PASSWORD'), element = password.getEl().dom;
      var input = element.tagName === 'INPUT' ? element : element.querySelector('input');
      var reveal = document.getElementById('dpanel-show-password');
      var passwordRow = reveal.parentNode;
      if (input.parentNode !== passwordRow) {
        input.parentNode.insertBefore(passwordRow, input);
        passwordRow.insertBefore(input, reveal);
      }
      function maskPassword() { input.type = 'password'; }
      maskPassword();
      reveal.onpointerdown = function (event) {
        if (event.isPrimary && event.button === 0) {
          if (reveal.hasPointerCapture(event.pointerId)) reveal.releasePointerCapture(event.pointerId);
          input.type = 'text';
        }
      };
      reveal.onpointerup = reveal.onpointerleave = reveal.onpointercancel = reveal.onblur = maskPassword;
      reveal.onkeydown = function (event) {
        if (event.key === ' ' || event.key === 'Enter') {
          event.preventDefault();
          if (!event.repeat) input.type = 'text';
        }
      };
      reveal.onkeyup = function (event) {
        if (event.key === ' ' || event.key === 'Enter') { event.preventDefault(); maskPassword(); }
      };
      window.addEventListener('blur', maskPassword);
      step.endPasswordReveal = function () { maskPassword(); window.removeEventListener('blur', maskPassword); };
      var portElement = step.getComponent('DP_APP_SERVER_PORT').getEl().dom;
      var port = portElement.tagName === 'INPUT' ? portElement : portElement.querySelector('input');
      function alignField() {
        var x = port.getBoundingClientRect().left;
        row.firstElementChild.style.width = Math.max(0, x - row.getBoundingClientRect().left) + 'px';
        [hint, document.getElementById('dpanel-port-hint'), document.getElementById('dpanel-password-hint')].forEach(function (item) {
          item.style.paddingLeft = Math.max(0, x - item.getBoundingClientRect().left) + 'px';
        });
      }
      step.dpanelFieldLayout = new ResizeObserver(alignField);
      step.dpanelFieldLayout.observe(row); step.dpanelFieldLayout.observe(port);
      if (!step.dpanelPasswordInit) {
        if (!password.getValue()) {
          var alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
          var bytes = window.crypto.getRandomValues(new Uint8Array(10)), value = '';
          for (var i = 0; i < bytes.length; i++) value += alphabet.charAt(bytes[i] & 63);
          password.setValue(value);
        }
        step.dpanelPasswordInit = true;
      }
    }",
ACCESS
cat <<'WIZARD'
    "deactivate_v2": "{ arguments[0].endPasswordReveal(); arguments[0].dpanelFieldLayout.disconnect(); }",
    "items": [
      {
        "desc": "<strong>${accessTitle}</strong>"
      },
      {
        "desc": "<div id='dpanel-access-row' role='radiogroup' aria-labelledby='dpanel-access-label' style='display:flex;align-items:center;font-size:13px;white-space:nowrap'><span id='dpanel-access-label' style='flex:none;width:65px'>${listenLabel}:</span><label><input type='radio' name='dpanel-access' style='margin-left:0' checked> ${listenAll}</label><label style='margin-left:10px'><input type='radio' name='dpanel-access'> ${listenLocal}</label></div><small id='dpanel-access-hint' aria-live='polite' style='display:block;margin-top:6px;color:#666'><span>${listenAllAdvice}</span><span hidden>${listenLocalAdvice}</span></small>"
      },
      {
        "type": "multiselect",
        "subitems": [
          { "key": "wizard_listen_local", "desc": "", "defaultValue": false }
        ]
      },
      {
        "type": "textfield",
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
          }
        ]
      },
      {
        "desc": "<small id='dpanel-port-hint' style='display:block;color:#666'>${portAdvice}</small>"
      },
      {
        "desc": "<strong>${accountTitle}</strong>"
      },
      {
        "type": "textfield",
        "subitems": [
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
      },
      {
        "desc": "<span style='display:inline-flex;align-items:center;gap:4px;vertical-align:middle'><button id='dpanel-show-password' type='button' aria-label='${showPassword}' title='${showPassword}' style='display:inline-flex;align-items:center;justify-content:center;width:28px;height:28px;padding:0;border:0;background:transparent;color:#526477;cursor:pointer;touch-action:none;user-select:none'><svg aria-hidden='true' style='pointer-events:none' width='18' height='18' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='1.8'><path d='M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z'/><circle cx='12' cy='12' r='3'/></svg></button></span><small id='dpanel-password-hint' style='display:block;color:#666'>${passwordAdvice}</small>"
      }
    ]
  },
  {
    "step_title": "${dockerTitle}",
    "items": [
      {
        "desc": "<strong style='color:#b42318'>${dockerCopyAdviceBeforeHelp}<a href='${helpUrl}' target='_blank' rel='noopener noreferrer' style='color:inherit;text-decoration:underline'>${dockerCopyAdviceHelp}</a>${dockerCopyAdviceAfterHelp}</strong>"
      },
      {
        "desc": "<label for='wizard_docker_socket_command'><strong>${socketLabel}</strong></label><textarea id='wizard_docker_socket_command' readonly rows='2' style='display:block;width:100%;box-sizing:border-box'>sudo sh -c '/usr/syno/sbin/synogroup --memberadd "$(stat -c "%G" /var/run/docker.sock)" dpanel && /usr/syno/bin/synopkg restart dpanel'</textarea><small style='color:#666'>${dockerAdvice}</small>"
      },
      {
        "desc": "<a href='${helpUrl}' target='_blank' rel='noopener noreferrer'>${helpLink}</a> &middot; <small style='color:#666'>${logHint}</small>"
      }
    ]
  }
]
WIZARD
} | write_wizard
