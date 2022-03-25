{
  "targets": [
    {
      "target_name": "bindings",
      "sources": [
        "src/export.cc"
      ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")"
      ],
      "dependencies": [
        "<!(node -p \"require('node-addon-api').gyp\")"
      ],
      "cflags!": ["-fno-exceptions"],
      "cflags_cc!": ["-fno-exceptions"],
      "defines": [
        "NAPI_CPP_EXCEPTIONS",
        "NAPI_VERSION=6",
      ],
      "conditions": [
        [
          'OS=="mac"',
          {
            "sources": [
                'src/impl_mac.mm'
            ],
            'link_settings': {
              'libraries': [
                '-framework CoreFoundation',
                '-framework AppKit',
              ]
            },
            "xcode_settings": {
              "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
              "CLANG_ENABLE_OBJC_ARC": "YES",
              'OTHER_CFLAGS': [
                '-ObjC++',
                '-std=c++17'
              ]
            },
          }
        ],
      ]
    }
  ]
}
