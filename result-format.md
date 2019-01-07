# Structure of test result directory
This document describes the structure of the test result directory. It is still WIP.

## Test module details
For each test module exists a JSON document `details-$module_name.json` like the subsequent
example. The comments in this example describe the meaning of the fields.

```
[ // list of steps
   { // object describing a step: the matched needle information (area/json/needle on top-level), other
     // candidates (area/json/needle on top-level), tags, ...
      "tags" : [ // considered tags
         "displaymanager",
         "displaymanager-password-prompt",
         "generic-desktop",
         "screenlock",
         "screenlock-password"
      ],
      "properties" : [], // TODO
      "result" : "ok", // whether it matched or not ("ok", "softfail", "fail" or "unk")
      "frametime" : [ // when the screenshot has been taken (TODO: actually a duration for displaying wall-clock time?)
         "180.42",
         "180.46"
      ],
      "area" : [ // areas of the matching needle
         {
            "x" : 0,
            "y" : 1
            "w" : 1024,
            "h" : 767,
            "result" : "ok", // whether it matched or not ("ok" or "fail")
            "similarity" : 98, // how well it matched, value from 0 to 100
         }
      ],
      "needles" : [ // considered candidate needles, nested structure is the same as for the match
         {
            "name" : "consoletest_finish-gnome-leap15.0-20180416",
            "error" : 0.0245306656203335,
            "json" : "tests/opensuse/products/opensuse/needles/consoletest_finish-gnome-leap15.0-20180416.json",
            "area" : [ //
               {
                  "x" : 0
                  "y" : 0,
                  "w" : 1024,
                  "h" : 361,
                  "similarity" : 84,
                  "result" : "fail",
               }
            ]
         },
        // more mismatched candidates omitted
      ],
      "json" : "tests/opensuse/products/opensuse/needles/consoletest_finish-gnome-TW-20180307.json",
      "needle" : "consoletest_finish-gnome-TW-20180307",
      "screenshot" : "shutdown-1.png"
   },
   {
      "needles" : [
         {
            "json" : "tests/opensuse/products/opensuse/needles/desktop-runner-gnome-unfocused3.19.91+-20170628.json",
            "area" : [
               {
                  "y" : 480,
                  "similarity" : 15,
                  "w" : 343,
                  "result" : "fail",
                  "x" : 324,
                  "h" : 152
               }
            ],
            "name" : "desktop-runner-gnome-unfocused3.19.91+-20170628",
            "error" : 0.707524947232352
         },
        // more mismatched candidates omitted
      ],
      "tags" : [
         "desktop-runner"
      ],
      "result" : "unk",
      "frametime" : [
         "182.96",
         "183.00"
      ],
      "screenshot" : "shutdown-2.png"
   },
   {
      "frametime" : [
         "183.00",
         "183.04"
      ],
      "area" : [
         {
            "h" : 263,
            "x" : 290,
            "y" : 242,
            "result" : "ok",
            "similarity" : 98,
            "w" : 458
         }
      ],
      "properties" : [],
      "error": 42.0,
      "tags" : [
         "displaymanager",
         "displaymanager-password-prompt",
         "generic-desktop",
         "screenlock",
         "screenlock-password"
      ],
      "result" : "ok",
      "json" : "tests/opensuse/products/opensuse/needles/gnome-screenlock-password-Tumbleweed-20181012.json",
      "needles" : [
         {
            "json" : "tests/opensuse/products/opensuse/needles/first_boot-displaymanager-password-prompt-20180313.json",
            "area" : [
               {
                  "x" : 280,
                  "h" : 207,
                  "y" : 352,
                  "result" : "fail",
                  "w" : 488,
                  "similarity" : 95
               }
            ],
            "name" : "first_boot-displaymanager-password-prompt-20180313",
            "error" : 0.00160212814504912 // TODO: formula how this relates to the percentage in the web UI
         },
         // more mismatched candidates omitted
      ],
      "needle" : "gnome-screenlock-password-Tumbleweed-20181012",
      "error" : 0.0005 // TODO: formula how this relates to the percentage in the web UI
      "screenshot" : "shutdown-3.png"
   },
   // more detail steps omitted
]
```
