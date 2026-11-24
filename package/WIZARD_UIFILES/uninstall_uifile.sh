#!/bin/sh
set -eu

write_wizard <<'WIZARD'
[
  {
    "step_title": "${uninstallTitle}",
    "items": [
      {
        "type": "singleselect",
        "desc": "${uninstallAdvice}",
        "subitems": [
          {
            "key": "wizard_keep_data",
            "desc": "${keepData}",
            "defaultValue": true
          },
          {
            "key": "wizard_delete_data",
            "desc": "${deleteData}",
            "defaultValue": false
          }
        ]
      }
    ]
  }
]
WIZARD
