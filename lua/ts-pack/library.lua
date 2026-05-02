local M = {}

M.registry = {
  ada = {
    src = 'https://github.com/briot/tree-sitter-ada',
    version = '6b58259a08b1a22ba0247a7ce30be384db618da6',
  },
  agda = {
    src = 'https://github.com/tree-sitter/tree-sitter-agda',
    version = 'e8d47a6987effe34d5595baf321d82d3519a8527',
  },
  angular = {
    src = 'https://github.com/dlvandenberg/tree-sitter-angular',
    version = 'f0d0685701b70883fa2dfe94ee7dc27965cab841',
    requires = {
      'html',
      'html_tags',
    },
  },
  apex = {
    src = 'https://github.com/aheber/tree-sitter-sfapex',
    version = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
    location = 'apex',
  },
  arduino = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-arduino',
    version = '11dd46c9ae25135c473c0003a133bb06a484af0c',
    requires = {
      'cpp',
    },
  },
  asm = {
    src = 'https://github.com/RubixDev/tree-sitter-asm',
    version = '839741fef4dab5128952334624905c82b40c7133',
  },
  astro = {
    src = 'https://github.com/virchau13/tree-sitter-astro',
    version = '213f6e6973d9b456c6e50e86f19f66877e7ef0ee',
    requires = {
      'html',
      'html_tags',
    },
  },
  authzed = {
    src = 'https://github.com/mleonidas/tree-sitter-authzed',
    version = '83e5c26a8687eb4688fe91d690c735cc3d21ad81',
  },
  awk = {
    src = 'https://github.com/Beaglefoot/tree-sitter-awk',
    version = '34bbdc7cce8e803096f47b625979e34c1be38127',
  },
  bash = {
    src = 'https://github.com/tree-sitter/tree-sitter-bash',
    version = 'a06c2e4415e9bc0346c6b86d401879ffb44058f7',
    queries = 'queries',
  },
  bass = {
    src = 'https://github.com/vito/tree-sitter-bass',
    version = '28dc7059722be090d04cd751aed915b2fee2f89a',
  },
  beancount = {
    src = 'https://github.com/polarmutex/tree-sitter-beancount',
    version = '429cff869513cf9e34a2cf604fbfaaedc467e809',
  },
  bibtex = {
    src = 'https://github.com/latex-lsp/tree-sitter-bibtex',
    version = '8d04ed27b3bc7929f14b7df9236797dab9f3fa66',
  },
  bicep = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-bicep',
    version = 'bff59884307c0ab009bd5e81afd9324b46a6c0f9',
  },
  bitbake = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-bitbake',
    version = 'a5d04fdb5a69a02b8fa8eb5525a60dfb5309b73b',
  },
  blade = {
    src = 'https://github.com/EmranMR/tree-sitter-blade',
    version = 'b9436b7b936907aff730de0dac1b99d7c632cc86',
  },
  bp = {
    src = 'https://github.com/ambroisie/tree-sitter-bp',
    version = 'ee641d15390183d7535777947ce0f2f1fbcee69f',
  },
  bpftrace = {
    src = 'https://github.com/sgruszka/tree-sitter-bpftrace',
    version = '774f4458ad39691336ead1ee361b22434c4cdec7',
  },
  brightscript = {
    src = 'https://github.com/ajdelcimmuto/tree-sitter-brightscript',
    version = '253fdfaa23814cb46c2d5fc19049fa0f2f62c6da',
  },
  c = {
    src = 'https://github.com/tree-sitter/tree-sitter-c',
    version = 'ae19b676b13bdcc13b7665397e6d9b14975473dd',
    queries = 'queries',
  },
  c3 = {
    src = 'https://github.com/c3lang/tree-sitter-c3',
    version = '78e2ae9cff29ef8ca6666006abe80f1236d42996',
  },
  c_sharp = {
    src = 'https://github.com/tree-sitter/tree-sitter-c-sharp',
    version = '88366631d598ce6595ec655ce1591b315cffb14c',
  },
  caddy = {
    src = 'https://github.com/opa-oz/tree-sitter-caddy',
    version = '2686186edb61be47960431c93a204fb249681360',
  },
  cairo = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-cairo',
    version = '6238f609bea233040fe927858156dee5515a0745',
  },
  capnp = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-capnp',
    version = '7b0883c03e5edd34ef7bcf703194204299d7099f',
  },
  chatito = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-chatito',
    version = 'c0ed82c665b732395073f635c74c300f09530a7f',
  },
  circom = {
    src = 'https://github.com/Decurity/tree-sitter-circom',
    version = '02150524228b1e6afef96949f2d6b7cc0aaf999e',
  },
  clojure = {
    src = 'https://github.com/sogaiu/tree-sitter-clojure',
    version = 'e43eff80d17cf34852dcd92ca5e6986d23a7040f',
    queries = 'queries',
  },
  cmake = {
    src = 'https://github.com/uyha/tree-sitter-cmake',
    version = 'c7b2a71e7f8ecb167fad4c97227c838439280175',
  },
  comment = {
    src = 'https://github.com/stsewd/tree-sitter-comment',
    version = '66272d2b6c73fb61157541b69dd0a7ce7b42a5ad',
  },
  commonlisp = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-commonlisp',
    version = '32323509b3d9fe96607d151c2da2c9009eb13a2f',
  },
  cooklang = {
    src = 'https://github.com/addcninblue/tree-sitter-cooklang',
    version = '4ebe237c1cf64cf3826fc249e9ec0988fe07e58e',
  },
  corn = {
    src = 'https://github.com/jakestanger/tree-sitter-corn',
    version = '464654742cbfd3a3de560aba120998f1d5dfa844',
  },
  cpon = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-cpon',
    version = '594289eadfec719198e560f9d7fd243c4db678d5',
  },
  cpp = {
    src = 'https://github.com/tree-sitter/tree-sitter-cpp',
    version = '8b5b49eb196bec7040441bee33b2c9a4838d6967',
    requires = {
      'c',
    },
  },
  css = {
    src = 'https://github.com/tree-sitter/tree-sitter-css',
    version = 'dda5cfc5722c429eaba1c910ca32c2c0c5bb1a3f',
  },
  csv = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
    version = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
    location = 'csv',
    requires = {
      'tsv',
    },
  },
  cuda = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-cuda',
    version = '48b066f334f4cf2174e05a50218ce2ed98b6fd01',
    requires = {
      'cpp',
    },
  },
  cue = {
    src = 'https://github.com/eonpatapon/tree-sitter-cue',
    version = '20bb9195dac00b64c00ee494812abf3bf76f4181',
  },
  cylc = {
    src = 'https://github.com/elliotfontaine/tree-sitter-cylc',
    version = '6d1d81137112299324b526477ce1db989ab58fb8',
  },
  d = {
    src = 'https://github.com/gdamore/tree-sitter-d',
    version = 'fb028c8f14f4188286c2eef143f105def6fbf24f',
  },
  dart = {
    src = 'https://github.com/UserNobody14/tree-sitter-dart',
    version = '0fc19c3a57b1109802af41d2b8f60d8835c5da3a',
  },
  desktop = {
    src = 'https://github.com/ValdezFOmar/tree-sitter-desktop',
    version = 'v1.1.1',
  },
  devicetree = {
    src = 'https://github.com/joelspadin/tree-sitter-devicetree',
    version = 'e685f1f6ac1702b046415efb476444167d63e41a',
  },
  dhall = {
    src = 'https://github.com/jbellerb/tree-sitter-dhall',
    version = '62013259b26ac210d5de1abf64cf1b047ef88000',
  },
  diff = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-diff',
    version = '2520c3f934b3179bb540d23e0ef45f75304b5fed',
  },
  disassembly = {
    src = 'https://github.com/ColinKennedy/tree-sitter-disassembly',
    version = '0229c0211dba909c5d45129ac784a3f4d49c243a',
  },
  djot = {
    src = 'https://github.com/treeman/tree-sitter-djot',
    version = '74fac1f53c6d52aeac104b6874e5506be6d0cfe6',
  },
  dockerfile = {
    src = 'https://github.com/camdencheek/tree-sitter-dockerfile',
    version = '971acdd908568b4531b0ba28a445bf0bb720aba5',
  },
  dot = {
    src = 'https://github.com/rydesun/tree-sitter-dot',
    version = '80327abbba6f47530edeb0df9f11bd5d5c93c14d',
  },
  doxygen = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-doxygen',
    version = 'ccd998f378c3f9345ea4eeb223f56d7b84d16687',
  },
  dtd = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-xml',
    version = '5000ae8f22d11fbe93939b05c1e37cf21117162d',
    location = 'dtd',
  },
  earthfile = {
    src = 'https://github.com/glehmann/tree-sitter-earthfile',
    version = '5baef88717ad0156fd29a8b12d0d8245bb1096a8',
  },
  ebnf = {
    src = 'https://github.com/RubixDev/ebnf',
    version = '8e635b0b723c620774dfb8abf382a7f531894b40',
    location = 'crates/tree-sitter-ebnf',
  },
  ecma = {},
  editorconfig = {
    src = 'https://github.com/ValdezFOmar/tree-sitter-editorconfig',
    version = 'v2.0.0',
  },
  eds = {
    src = 'https://github.com/uyha/tree-sitter-eds',
    version = '26d529e6cfecde391a03c21d1474eb51e0285805',
  },
  eex = {
    src = 'https://github.com/connorlay/tree-sitter-eex',
    version = 'f742f2fe327463335e8671a87c0b9b396905d1d1',
  },
  elixir = {
    src = 'https://github.com/elixir-lang/tree-sitter-elixir',
    version = '7937d3b4d65fa574163cfa59394515d3c1cf16f4',
  },
  elm = {
    src = 'https://github.com/elm-tooling/tree-sitter-elm',
    version = '6d9511c28181db66daee4e883f811f6251220943',
  },
  elsa = {
    src = 'https://github.com/glapa-grossklag/tree-sitter-elsa',
    version = '0a66b2b3f3c1915e67ad2ef9f7dbd2a84820d9d7',
  },
  elvish = {
    src = 'https://github.com/elves/tree-sitter-elvish',
    version = '5e7210d945425b77f82cbaebc5af4dd3e1ad40f5',
  },
  embedded_template = {
    src = 'https://github.com/tree-sitter/tree-sitter-embedded-template',
    version = '3499d85f0a0d937c507a4a65368f2f63772786e1',
  },
  enforce = {
    src = 'https://github.com/simonvic/tree-sitter-enforce',
    version = 'eb2796871d966264cdb041b797416ef1757c8b4f',
  },
  erlang = {
    src = 'https://github.com/WhatsApp/tree-sitter-erlang',
    version = '1d78195c4fbb1fc027eb3e4220427f1eb8bfc89e',
  },
  facility = {
    src = 'https://github.com/FacilityApi/tree-sitter-facility',
    version = 'e4bfd3e960de9f4b4648acb1c92e9b95b47d8cfb',
  },
  faust = {
    src = 'https://github.com/khiner/tree-sitter-faust',
    version = '122dd101919289ea809bad643712fcb483a1bed0',
  },
  fennel = {
    src = 'https://github.com/alexmozaidze/tree-sitter-fennel',
    version = '3f0f6b24d599e92460b969aabc4f4c5a914d15a0',
  },
  fidl = {
    src = 'https://github.com/google/tree-sitter-fidl',
    version = '0a8910f293268e27ff554357c229ba172b0eaed2',
  },
  firrtl = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-firrtl',
    version = '8503d3a0fe0f9e427863cb0055699ff2d29ae5f5',
  },
  fish = {
    src = 'https://github.com/ram02z/tree-sitter-fish',
    version = 'fa2143f5d66a9eb6c007ba9173525ea7aaafe788',
  },
  foam = {
    src = 'https://github.com/FoamScience/tree-sitter-foam',
    version = '472c24f11a547820327fb1be565bcfff98ea96a4',
  },
  forth = {
    src = 'https://github.com/AlexanderBrevig/tree-sitter-forth',
    version = '360ef13f8c609ec6d2e80782af69958b84e36cd0',
  },
  fortran = {
    src = 'https://github.com/stadelmanma/tree-sitter-fortran',
    version = 'be30d90dc7dfa4080b9c4abed3f400c9163a88df',
  },
  fsh = {
    src = 'https://github.com/mgramigna/tree-sitter-fsh',
    version = 'fad2e175099a45efbc98f000cc196d3674cc45e0',
  },
  fsharp = {
    src = 'https://github.com/ionide/tree-sitter-fsharp',
    version = '1c2d9351d1f731c08cfdc4ed41e63126ae56e462',
    location = 'fsharp',
  },
  func = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-func',
    version = 'f780ca55e65e7d7360d0229331763e16c452fc98',
  },
  gap = {
    src = 'https://github.com/gap-system/tree-sitter-gap',
    version = 'ed2480d42281586932920527823b307bc45052b8',
  },
  gaptst = {
    src = 'https://github.com/gap-system/tree-sitter-gaptst',
    version = '69086d7627c03e1f4baf766bcef14c60d9e92331',
    requires = {
      'gap',
    },
  },
  gdscript = {
    src = 'https://github.com/PrestonKnopp/tree-sitter-gdscript',
    version = '9686853b696db07118ad110e440d6de0ca6498b4',
  },
  gdshader = {
    src = 'https://github.com/airblast-dev/tree-sitter-gdshader',
    version = '68268631c8b6dc093985f1246b099f81b30ea7d1',
  },
  git_config = {
    src = 'https://github.com/the-mikedavis/tree-sitter-git-config',
    version = '0fbc9f99d5a28865f9de8427fb0672d66f9d83a5',
  },
  git_rebase = {
    src = 'https://github.com/the-mikedavis/tree-sitter-git-rebase',
    version = '760ba8e34e7a68294ffb9c495e1388e030366188',
  },
  gitattributes = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-gitattributes',
    version = '1b7af09d45b579f9f288453b95ad555f1f431645',
  },
  gitcommit = {
    src = 'https://github.com/gbprod/tree-sitter-gitcommit',
    version = '33fe8548abcc6e374feaac5724b5a2364bf23090',
  },
  gitignore = {
    src = 'https://github.com/shunsambongi/tree-sitter-gitignore',
    version = 'f4685bf11ac466dd278449bcfe5fd014e94aa504',
  },
  gleam = {
    src = 'https://github.com/gleam-lang/tree-sitter-gleam',
    version = '0bb1b0ae1a3555180ae7b0004851da747fc230d1',
  },
  glimmer = {
    src = 'https://github.com/ember-tooling/tree-sitter-glimmer',
    version = '88af85568bde3b91acb5d4c352ed094d0c1f9d84',
  },
  glimmer_javascript = {
    src = 'https://github.com/NullVoxPopuli/tree-sitter-glimmer-javascript',
    version = '5cc865a2a0a77cbfaf5062c8fcf2a9919bd54f87',
    requires = {
      'ecma',
    },
  },
  glimmer_typescript = {
    src = 'https://github.com/NullVoxPopuli/tree-sitter-glimmer-typescript',
    version = '12d98944c1d5077b957cbdb90d663a7c4d50118c',
    requires = {
      'typescript',
    },
  },
  glsl = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-glsl',
    version = '24a6c8ef698e4480fecf8340d771fbcb5de8fbb4',
    requires = {
      'c',
    },
  },
  gn = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-gn',
    version = 'bc06955bc1e3c9ff8e9b2b2a55b38b94da923c05',
  },
  gnuplot = {
    src = 'https://github.com/dpezto/tree-sitter-gnuplot',
    version = '8923c1e38b9634a688a6c0dce7c18c8ffb823e79',
  },
  go = {
    src = 'https://github.com/tree-sitter/tree-sitter-go',
    version = '2346a3ab1bb3857b48b29d779a1ef9799a248cd7',
    queries = 'queries',
  },
  goctl = {
    src = 'https://github.com/chaozwn/tree-sitter-goctl',
    version = '49c43532689fe1f53e8b9e009d0521cab02c432b',
  },
  godot_resource = {
    src = 'https://github.com/PrestonKnopp/tree-sitter-godot-resource',
    version = '302c1895f54bf74d53a08572f7b26a6614209adc',
  },
  gomod = {
    src = 'https://github.com/camdencheek/tree-sitter-go-mod',
    version = '2e886870578eeba1927a2dc4bd2e2b3f598c5f9a',
    queries = 'queries',
  },
  gosum = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-go-sum',
    version = '27816eb6b7315746ae9fcf711e4e1396dc1cf237',
    queries = 'queries',
  },
  gotmpl = {
    src = 'https://github.com/ngalaiko/tree-sitter-go-template',
    version = 'aa71f63de226c5592dfbfc1f29949522d7c95fac',
  },
  gowork = {
    src = 'https://github.com/omertuc/tree-sitter-go-work',
    version = '949a8a470559543857a62102c84700d291fc984c',
  },
  gpg = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-gpg-config',
    version = '4024eb268c59204280f8ac71ef146b8ff5e737f6',
  },
  graphql = {
    src = 'https://github.com/bkegley/tree-sitter-graphql',
    version = '5e66e961eee421786bdda8495ed1db045e06b5fe',
  },
  gren = {
    src = 'https://github.com/MaeBrooks/tree-sitter-gren',
    version = 'c36aac51a915fdfcaf178128ba1e9c2205b25930',
  },
  groovy = {
    src = 'https://github.com/murtaza64/tree-sitter-groovy',
    version = '781d9cd1b482a70a6b27091e5c9e14bbcab3b768',
    queries = 'queries',
  },
  groq = {
    src = 'https://github.com/ajrussellaudio/tree-sitter-groq',
    version = '1fa1ab0eb391a270957e8ad8c731b492e3645649',
  },
  gstlaunch = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-gstlaunch',
    version = '549aef253fd38a53995cda1bf55c501174372bf7',
  },
  hack = {
    src = 'https://github.com/slackhq/tree-sitter-hack',
    version = '1a7ded90288189746c54861ac144ede97df95081',
  },
  hare = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-hare',
    version = 'eed7ddf6a66b596906aa8ca3d40521b8278adc6f',
  },
  haskell = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-haskell',
    version = '7fa19f195803a77855f036ee7f49e4b22856e338',
  },
  haskell_persistent = {
    src = 'https://github.com/MercuryTechnologies/tree-sitter-haskell-persistent',
    version = '577259b4068b2c281c9ebf94c109bd50a74d5857',
  },
  hcl = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-hcl',
    version = '64ad62785d442eb4d45df3a1764962dafd5bc98b',
  },
  heex = {
    src = 'https://github.com/connorlay/tree-sitter-heex',
    version = '5842537f734d7c12685bf27d6005313e3e5a47a0',
  },
  helm = {
    src = 'https://github.com/ngalaiko/tree-sitter-go-template',
    version = 'aa71f63de226c5592dfbfc1f29949522d7c95fac',
    location = 'dialects/helm',
  },
  hjson = {
    src = 'https://github.com/winston0410/tree-sitter-hjson',
    version = '02fa3b79b3ff9a296066da6277adfc3f26cbc9e0',
    requires = {
      'json',
    },
  },
  hlsl = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-hlsl',
    version = 'bab9111922d53d43668fabb61869bec51bbcb915',
    requires = {
      'cpp',
    },
  },
  hlsplaylist = {
    src = 'https://github.com/Freed-Wu/tree-sitter-hlsplaylist',
    version = '3bfda9271e3adb08d35f47a2102fe957009e1c55',
  },
  hocon = {
    src = 'https://github.com/antosha417/tree-sitter-hocon',
    version = 'c390f10519ae69fdb03b3e5764f5592fb6924bcc',
  },
  hoon = {
    src = 'https://github.com/urbit-pilled/tree-sitter-hoon',
    version = '1545137aadcc63660c47db9ad98d02fa602655d0',
  },
  html = {
    src = 'https://github.com/tree-sitter/tree-sitter-html',
    version = '73a3947324f6efddf9e17c0ea58d454843590cc0',
    requires = {
      'html_tags',
    },
  },
  html_tags = {},
  htmldjango = {
    src = 'https://github.com/interdependence/tree-sitter-htmldjango',
    version = '3a643167ad9afac5d61e092f08ff5b054576fadf',
  },
  http = {
    src = 'https://github.com/rest-nvim/tree-sitter-http',
    version = 'db8b4398de90b6d0b6c780aba96aaa2cd8e9202c',
  },
  hurl = {
    src = 'https://github.com/pfeiferj/tree-sitter-hurl',
    version = '597efbd7ce9a814bb058f48eabd055b1d1e12145',
  },
  hyprlang = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-hyprlang',
    version = 'cecd6b748107d9da1f7b4ca03ef95f1f71d93b8f',
  },
  idl = {
    src = 'https://github.com/cathaysia/tree-sitter-idl',
    version = 'fb65762a13538b397e41a5fc1e9564c9df841410',
  },
  idris = {
    src = 'https://github.com/kayhide/tree-sitter-idris',
    version = 'c56a25cf57c68ff929356db25505c1cc4c7820f6',
  },
  ini = {
    src = 'https://github.com/justinmk/tree-sitter-ini',
    version = 'e4018b5176132b4f3c5d6e61cea383f42288d0f5',
  },
  inko = {
    src = 'https://github.com/inko-lang/tree-sitter-inko',
    version = 'v0.5.1',
  },
  ispc = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-ispc',
    version = '9b2f9aec2106b94b4e099fe75e73ebd8ae707c04',
    requires = {
      'c',
    },
  },
  janet_simple = {
    src = 'https://github.com/sogaiu/tree-sitter-janet-simple',
    version = 'd183186995204314700be3e9e0a48053ea16b350',
  },
  java = {
    src = 'https://github.com/tree-sitter/tree-sitter-java',
    version = 'e10607b45ff745f5f876bfa3e94fbcc6b44bdc11',
    queries = 'queries',
  },
  javadoc = {
    src = 'https://github.com/rmuir/tree-sitter-javadoc',
    version = 'e2f56b4d0df08f6ed5df8bae266f9e75b340a9ab',
    queries = 'queries',
  },
  javascript = {
    src = 'https://github.com/tree-sitter/tree-sitter-javascript',
    version = '58404d8cf191d69f2674a8fd507bd5776f46cb11',
    queries = 'queries',
    requires = {
      'ecma',
      'jsx',
    },
  },
  jinja = {
    src = 'https://github.com/cathaysia/tree-sitter-jinja',
    version = '413dba9fea354b62f6adada1815b2f504e32ffb5',
    location = 'tree-sitter-jinja',
    requires = {
      'jinja_inline',
    },
  },
  jinja_inline = {
    src = 'https://github.com/cathaysia/tree-sitter-jinja',
    version = '413dba9fea354b62f6adada1815b2f504e32ffb5',
    location = 'tree-sitter-jinja_inline',
  },
  jjdescription = {
    src = 'https://github.com/ribru17/tree-sitter-jjdescription',
    version = 'v1.0.3',
  },
  jq = {
    src = 'https://github.com/flurie/tree-sitter-jq',
    version = 'c204e36d2c3c6fce1f57950b12cabcc24e5cc4d9',
  },
  jsdoc = {
    src = 'https://github.com/tree-sitter/tree-sitter-jsdoc',
    version = '658d18dcdddb75c760363faa4963427a7c6b52db',
  },
  json = {
    src = 'https://github.com/tree-sitter/tree-sitter-json',
    version = '001c28d7a29832b06b0e831ec77845553c89b56d',
  },
  json5 = {
    src = 'https://github.com/Joakker/tree-sitter-json5',
    version = 'aa630ef48903ab99e406a8acd2e2933077cc34e1',
  },
  jsonnet = {
    src = 'https://github.com/sourcegraph/tree-sitter-jsonnet',
    version = 'ddd075f1939aed8147b7aa67f042eda3fce22790',
  },
  jsx = {},
  julia = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-julia',
    version = '8454f266717232525ed03c7b09164b0404a03150',
  },
  just = {
    src = 'https://github.com/IndianBoy42/tree-sitter-just',
    version = '5685543a6e64f66335e25518c9ae8ffa1dae3d01',
  },
  kcl = {
    src = 'https://github.com/kcl-lang/tree-sitter-kcl',
    version = 'b0b2eb38009e04035a6e266c7e11e541f3caab7c',
  },
  kconfig = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-kconfig',
    version = '9ac99fe4c0c27a35dc6f757cef534c646e944881',
  },
  kdl = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-kdl',
    version = 'b37e3d58e5c5cf8d739b315d6114e02d42e66664',
  },
  kitty = {
    src = 'https://github.com/OXY2DEV/tree-sitter-kitty',
    version = 'fa6ab3fd32d890a0217495c96b35761e6d2dcb5b',
  },
  kos = {
    src = 'https://github.com/kos-lang/tree-sitter-kos',
    version = '03b261c1a78b71c38cf4616497f253c4a4ce118b',
  },
  kotlin = {
    src = 'https://github.com/fwcd/tree-sitter-kotlin',
    version = '93bfeee1555d2b1442d68c44b0afde2a3b069e46',
  },
  koto = {
    src = 'https://github.com/koto-lang/tree-sitter-koto',
    version = 'f8b3f62c0eed185dca1559789e78759d4bee60e5',
  },
  kusto = {
    src = 'https://github.com/Willem-J-an/tree-sitter-kusto',
    version = '8353a1296607d6ba33db7c7e312226e5fc83e8ce',
  },
  lalrpop = {
    src = 'https://github.com/traxys/tree-sitter-lalrpop',
    version = '27b0f7bb55b4cabd8f01a933d9ee6a49dbfc2192',
  },
  latex = {
    src = 'https://github.com/latex-lsp/tree-sitter-latex',
    version = '7e0ecdc02926c7b9b2e0c76003d4fe7b0944f957',
    generate = true,
  },
  ledger = {
    src = 'https://github.com/cbarrete/tree-sitter-ledger',
    version = '22a1ab8195c1f6e808679f803007756fe7638c6f',
  },
  leo = {
    src = 'https://github.com/r001/tree-sitter-leo',
    version = '6bc5564917edacd070afc4d33cf5e2e677831ea9',
  },
  linkerscript = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-linkerscript',
    version = 'f99011a3554213b654985a4b0a65b3b032ec4621',
  },
  liquid = {
    src = 'https://github.com/hankthetank27/tree-sitter-liquid',
    version = '9566ca79911052919fce09d26f1f655b5e093857',
  },
  liquidsoap = {
    src = 'https://github.com/savonet/tree-sitter-liquidsoap',
    version = '0169d92b0a93e9f32289533ef23abdafca579e56',
  },
  llvm = {
    src = 'https://github.com/benwilliamgraham/tree-sitter-llvm',
    version = '2914786ae6774d4c4e25a230f4afe16aa68fe1c1',
  },
  lua = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-lua',
    version = '10fe0054734eec83049514ea2e718b2a56acd0c9',
  },
  luadoc = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-luadoc',
    version = '873612aadd3f684dd4e631bdf42ea8990c57634e',
  },
  luap = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-luap',
    version = 'c134aaec6acf4fa95fe4aa0dc9aba3eacdbbe55a',
  },
  luau = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-luau',
    version = 'a8914d6c1fc5131f8e1c13f769fa704c9f5eb02f',
    requires = {
      'lua',
    },
  },
  m68k = {
    src = 'https://github.com/grahambates/tree-sitter-m68k',
    version = 'e128454c2210c0e0c10b68fe45ddb8fee80182a3',
  },
  make = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-make',
    version = '70613f3d812cbabbd7f38d104d60a409c4008b43',
  },
  markdown = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-markdown',
    version = 'f969cd3ae3f9fbd4e43205431d0ae286014c05b5',
    location = 'tree-sitter-markdown',
    requires = {
      'markdown_inline',
    },
  },
  markdown_inline = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-markdown',
    version = 'f969cd3ae3f9fbd4e43205431d0ae286014c05b5',
    location = 'tree-sitter-markdown-inline',
  },
  matlab = {
    src = 'https://github.com/acristoffers/tree-sitter-matlab',
    version = 'c2390a59016f74e7d5f75ef09510768b4f30217e',
  },
  menhir = {
    src = 'https://github.com/Kerl13/tree-sitter-menhir',
    version = 'be8866a6bcc2b563ab0de895af69daeffa88fe70',
  },
  mermaid = {
    src = 'https://github.com/monaqa/tree-sitter-mermaid',
    version = '90ae195b31933ceb9d079abfa8a3ad0a36fee4cc',
  },
  meson = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-meson',
    version = 'c84f3540624b81fc44067030afce2ff78d6ede05',
  },
  mlir = {
    src = 'https://github.com/artagnon/tree-sitter-mlir',
    version = '96fa0adc3028cc6a9d281370c9f213a457c4a2d0',
    generate = true,
  },
  muttrc = {
    src = 'https://github.com/neomutt/tree-sitter-muttrc',
    version = '173b0ab53a9c07962c9777189c4c70e90f1c1837',
  },
  nasm = {
    src = 'https://github.com/naclsn/tree-sitter-nasm',
    version = 'd1b3638d017f2a8585e26dcfc66fe1df94185e30',
  },
  nginx = {
    src = 'https://github.com/opa-oz/tree-sitter-nginx',
    version = '47ade644d754cce57974aac44d2c9450e823d4f4',
  },
  nickel = {
    src = 'https://github.com/nickel-lang/tree-sitter-nickel',
    version = 'b5b6cc3bc7b9ea19f78fed264190685419cd17a8',
  },
  nim = {
    src = 'https://github.com/alaviss/tree-sitter-nim',
    version = '3878440d9398515ae053c6f6024986e69868bb74',
    requires = {
      'nim_format_string',
    },
  },
  nim_format_string = {
    src = 'https://github.com/aMOPel/tree-sitter-nim-format-string',
    version = 'd45f75022d147cda056e98bfba68222c9c8eca3a',
  },
  ninja = {
    src = 'https://github.com/alemuller/tree-sitter-ninja',
    version = '0a95cfdc0745b6ae82f60d3a339b37f19b7b9267',
  },
  nix = {
    src = 'https://github.com/nix-community/tree-sitter-nix',
    version = 'eabf96807ea4ab6d6c7f09b671a88cd483542840',
  },
  nqc = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-nqc',
    version = '14e6da1627aaef21d2b2aa0c37d04269766dcc1d',
  },
  nu = {
    src = 'https://github.com/nushell/tree-sitter-nu',
    version = '696d257f6b652edb50878a783b30ad7833dec49e',
  },
  objc = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-objc',
    version = '181a81b8f23a2d593e7ab4259981f50122909fda',
    requires = {
      'c',
    },
  },
  objdump = {
    src = 'https://github.com/ColinKennedy/tree-sitter-objdump',
    version = '28d3b2e25a0b1881d1b47ed1924ca276c7003d45',
  },
  ocaml = {
    src = 'https://github.com/tree-sitter/tree-sitter-ocaml',
    version = '5a979b3ec7f1fe990b8e8c4412294a0cf7228e45',
    location = 'grammars/ocaml',
  },
  ocaml_interface = {
    src = 'https://github.com/tree-sitter/tree-sitter-ocaml',
    version = '5a979b3ec7f1fe990b8e8c4412294a0cf7228e45',
    location = 'grammars/interface',
    requires = {
      'ocaml',
    },
  },
  ocamllex = {
    src = 'https://github.com/atom-ocaml/tree-sitter-ocamllex',
    version = '33722b8be73079946a7c6dd9598e3f57956ed36d',
    generate = true,
  },
  odin = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-odin',
    version = 'd2ca8efb4487e156a60d5bd6db2598b872629403',
  },
  pascal = {
    src = 'https://github.com/Isopod/tree-sitter-pascal',
    version = '042119eca2e18a60e56317fb06ee3ba5c32cb447',
  },
  passwd = {
    src = 'https://github.com/ath3/tree-sitter-passwd',
    version = '20239395eacdc2e0923a7e5683ad3605aee7b716',
  },
  pem = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-pem',
    version = 'e525b177a229b1154fd81bc0691f943028d9e685',
  },
  perl = {
    src = 'https://github.com/tree-sitter-perl/tree-sitter-perl',
    version = 'ea9667dc65a816acace002a2b1b099978785ca33',
    generate = true,
  },
  php = {
    src = 'https://github.com/tree-sitter/tree-sitter-php',
    version = '3f2465c217d0a966d41e584b42d75522f2a3149e',
    location = 'php',
    requires = {
      'php_only',
    },
  },
  php_only = {
    src = 'https://github.com/tree-sitter/tree-sitter-php',
    version = '3f2465c217d0a966d41e584b42d75522f2a3149e',
    location = 'php_only',
  },
  phpdoc = {
    src = 'https://github.com/claytonrcarter/tree-sitter-phpdoc',
    version = '12d50307e6c02e5f4f876fa6cf2edea1f7808c0d',
  },
  pioasm = {
    src = 'https://github.com/leo60228/tree-sitter-pioasm',
    version = 'afece58efdb30440bddd151ef1347fa8d6f744a9',
  },
  pkl = {
    src = 'https://github.com/apple/tree-sitter-pkl',
    version = 'f5beed1da8e5fc856a1a11e29a929d0b7cdcfe3c',
  },
  po = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-po',
    version = 'bd860a0f57f697162bf28e576674be9c1500db5e',
  },
  pod = {
    src = 'https://github.com/tree-sitter-perl/tree-sitter-pod',
    version = '57c606aa3373ba876d44113d13fe7bdc2c060723',
    generate = true,
  },
  poe_filter = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-poe-filter',
    version = '205a7d576984feb38a9fc2d8cfe729617f9e0548',
  },
  pony = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-pony',
    version = '73ff874ae4c9e9b45462673cbc0a1e350e2522a7',
  },
  powershell = {
    src = 'https://github.com/airbus-cert/tree-sitter-powershell',
    version = '73800ecc8bddeee8f1079a5a2e0c13c3d00269bb',
  },
  printf = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-printf',
    version = 'ec4e5674573d5554fccb87a887c97d4aec489da7',
  },
  prisma = {
    src = 'https://github.com/victorhqc/tree-sitter-prisma',
    version = '3556b2c1f20ec9ac91e92d32c43d9d2a0ca3cc49',
  },
  problog = {
    src = 'https://github.com/foxyseta/tree-sitter-prolog',
    version = 'd8d415f6a1cf80ca138524bcc395810b176d40fa',
    location = 'grammars/problog',
    requires = {
      'prolog',
    },
  },
  prolog = {
    src = 'https://github.com/foxyseta/tree-sitter-prolog',
    version = 'd8d415f6a1cf80ca138524bcc395810b176d40fa',
    location = 'grammars/prolog',
  },
  promql = {
    src = 'https://github.com/MichaHoffmann/tree-sitter-promql',
    version = '77625d78eebc3ffc44d114a07b2f348dff3061b0',
  },
  properties = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-properties',
    version = '6310671b24d4e04b803577b1c675d765cbd5773b',
  },
  proto = {
    src = 'https://github.com/coder3101/tree-sitter-proto',
    version = 'd65a18ce7c2242801f702770114ad08056c7f8c9',
  },
  prql = {
    src = 'https://github.com/PRQL/tree-sitter-prql',
    version = '09e158cd3650581c0af4c49c2e5b10c4834c8646',
  },
  psv = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
    version = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
    location = 'psv',
    requires = {
      'tsv',
    },
  },
  pug = {
    src = 'https://github.com/zealot128/tree-sitter-pug',
    version = '13e9195370172c86a8b88184cc358b23b677cc46',
  },
  puppet = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-puppet',
    version = '15f192929b7d317f5914de2b4accd37b349182a6',
  },
  purescript = {
    src = 'https://github.com/postsolar/tree-sitter-purescript',
    version = 'f541f95ffd6852fbbe88636317c613285bc105af',
  },
  pymanifest = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-pymanifest',
    version = 'debbdb83fe6356adc7261c41c69b45ba49c97294',
  },
  python = {
    src = 'https://github.com/tree-sitter/tree-sitter-python',
    version = 'v0.25.0',
  },
  ql = {
    src = 'https://github.com/tree-sitter/tree-sitter-ql',
    version = '1fd627a4e8bff8c24c11987474bd33112bead857',
  },
  qmldir = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-qmldir',
    version = '6b2b5e41734bd6f07ea4c36ac20fb6f14061c841',
  },
  qmljs = {
    src = 'https://github.com/yuja/tree-sitter-qmljs',
    version = '0bec4359a7eb2f6c9220cd57372d87d236f66d59',
    requires = {
      'ecma',
    },
  },
  query = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-query',
    version = 'fc5409c6820dd5e02b0b0a309d3da2bfcde2db17',
  },
  r = {
    src = 'https://github.com/r-lib/tree-sitter-r',
    version = '0e6ef7741712c09dc3ee6e81c42e919820cc65ef',
  },
  racket = {
    src = 'https://github.com/6cdh/tree-sitter-racket',
    version = '54649be8b939341d2d5410b594ab954fe8814bd0',
  },
  ralph = {
    src = 'https://github.com/alephium/tree-sitter-ralph',
    version = 'f6d81bf7a4599c77388035439cf5801cd461ff77',
  },
  rasi = {
    src = 'https://github.com/Fymyte/tree-sitter-rasi',
    version = 'e735c6881d8b475aaa4ef8f0a2bdfd825b438143',
  },
  razor = {
    src = 'https://github.com/tris203/tree-sitter-razor',
    version = 'fe46ce5ea7d844e53d59bc96f2175d33691c61c5',
  },
  rbs = {
    src = 'https://github.com/joker1007/tree-sitter-rbs',
    version = '5282e2f36d4109f5315c1d9486b5b0c2044622bb',
  },
  re2c = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-re2c',
    version = 'c18a3c2f4b6665e35b7e50d6048ea3cff770c572',
  },
  readline = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-readline',
    version = '6b744c527aebd12e46a5ecb3aebdb8d621a8e83e',
  },
  regex = {
    src = 'https://github.com/tree-sitter/tree-sitter-regex',
    version = 'b2ac15e27fce703d2f37a79ccd94a5c0cbe9720b',
  },
  rego = {
    src = 'https://github.com/FallenAngel97/tree-sitter-rego',
    version = 'ddd39af81fe8b0288102a7cb97959dfce723e0f3',
  },
  requirements = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-requirements',
    version = 'caeb2ba854dea55931f76034978de1fd79362939',
  },
  rescript = {
    src = 'https://github.com/rescript-lang/tree-sitter-rescript',
    version = '43c2f1f35024918d415dc933d4cc534d6419fedf',
  },
  rifleconf = {
    src = 'https://github.com/purarue/tree-sitter-rifleconf',
    version = '6389ef0fc0d48f0397ec233109c074a0cb685e36',
  },
  rnoweb = {
    src = 'https://github.com/bamonroe/tree-sitter-rnoweb',
    version = '1a74dc0ed731ad07db39f063e2c5a6fe528cae7f',
  },
  robot = {
    src = 'https://github.com/Hubro/tree-sitter-robot',
    version = 'v1.3.0',
  },
  robots_txt = {
    src = 'https://github.com/opa-oz/tree-sitter-robots-txt',
    version = '0c066107e3548de79316a6a4ec771e2f7cf7c468',
  },
  roc = {
    src = 'https://github.com/faldor20/tree-sitter-roc',
    version = '40e52f343f1b1f270d6ecb2ca898ca9b8cba6936',
  },
  ron = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-ron',
    version = '78938553b93075e638035f624973083451b29055',
  },
  rst = {
    src = 'https://github.com/stsewd/tree-sitter-rst',
    version = '4e562e1598b95b93db4f3f64fe40ddefbc677a15',
  },
  ruby = {
    src = 'https://github.com/tree-sitter/tree-sitter-ruby',
    version = 'ad907a69da0c8a4f7a943a7fe012712208da6dee',
  },
  runescript = {
    src = 'https://github.com/2004Scape/tree-sitter-runescript',
    version = 'cf85bbd5da0c5ad243301d889c7f84d790a4cae4',
  },
  rust = {
    src = 'https://github.com/tree-sitter/tree-sitter-rust',
    version = '77a3747266f4d621d0757825e6b11edcbf991ca5',
  },
  scala = {
    src = 'https://github.com/tree-sitter/tree-sitter-scala',
    version = '14c5cfd2b8e0f057ba0f4f72ee4812b0ae6cdce3',
  },
  scfg = {
    src = 'https://github.com/rockorager/tree-sitter-scfg',
    version = 'd850fd470445d73de318a21d734d1e09e29b773c',
  },
  scheme = {
    src = 'https://github.com/6cdh/tree-sitter-scheme',
    version = 'c6cb7c7d7a04b3f5d999c28e2e9c0c31b2d50ece',
  },
  scss = {
    src = 'https://github.com/serenadeai/tree-sitter-scss',
    version = 'c478c6868648eff49eb04a4df90d703dc45b312a',
    requires = {
      'css',
    },
  },
  sflog = {
    src = 'https://github.com/aheber/tree-sitter-sfapex',
    version = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
    location = 'sflog',
  },
  slang = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-slang',
    version = '1dbcc4abc7b3cdd663eb03d93031167d6ed19f56',
  },
  slim = {
    src = 'https://github.com/theoo/tree-sitter-slim',
    version = 'a06113f5175b805a37d20df0a6f9d722e0ab6cfe',
  },
  slint = {
    src = 'https://github.com/slint-ui/tree-sitter-slint',
    version = '4d7ad0617c30f865f051bbac04a9826bea29f987',
  },
  smali = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-smali',
    version = 'fdfa6a1febc43c7467aa7e937b87b607956f2346',
  },
  smithy = {
    src = 'https://github.com/indoorvivants/tree-sitter-smithy',
    version = 'ec4fe14586f2b0a1bc65d6db17f8d8acd8a90433',
  },
  snakemake = {
    src = 'https://github.com/osthomas/tree-sitter-snakemake',
    version = '68010430c3e51c0e84c1ce21c6551df0e2469f51',
  },
  snl = {
    src = 'https://github.com/minijackson/tree-sitter-snl',
    version = '846e2d6809ac5863a15b5494f20fd267c21221c8',
  },
  solidity = {
    src = 'https://github.com/JoranHonig/tree-sitter-solidity',
    version = '048fe686cb1fde267243739b8bdbec8fc3a55272',
  },
  soql = {
    src = 'https://github.com/aheber/tree-sitter-sfapex',
    version = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
    location = 'soql',
  },
  sosl = {
    src = 'https://github.com/aheber/tree-sitter-sfapex',
    version = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
    location = 'sosl',
  },
  sourcepawn = {
    src = 'https://github.com/nilshelmig/tree-sitter-sourcepawn',
    version = '5a8fdd446b516c81e218245c12129c6ad4bccfa2',
  },
  sparql = {
    src = 'https://github.com/GordianDziwis/tree-sitter-sparql',
    version = '1ef52d35a73a2a5f2e433ecfd1c751c1360a923b',
  },
  sproto = {
    src = 'https://github.com/hanxi/tree-sitter-sproto',
    version = 'd554c1456e35e7b2690552d52921c987d0cf6799',
  },
  sql = {
    src = 'https://github.com/derekstride/tree-sitter-sql',
    version = '851e9cb257ba7c66cc8c14214a31c44d2f1e954e',
    branch = 'gh-pages',
  },
  squirrel = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-squirrel',
    version = '072c969749e66f000dba35a33c387650e203e96e',
  },
  ssh_config = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-ssh-config',
    version = '71d2693deadaca8cdc09e38ba41d2f6042da1616',
  },
  starlark = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-starlark',
    version = 'a453dbf3ba433db0e5ec621a38a7e59d72e4dc69',
  },
  strace = {
    src = 'https://github.com/sigmaSd/tree-sitter-strace',
    version = 'ac874ddfcc08d689fee1f4533789e06d88388f29',
  },
  styled = {
    src = 'https://github.com/mskelton/tree-sitter-styled',
    version = '319cdcaa0346ba6db668a222d938e5c3569e2a51',
  },
  supercollider = {
    src = 'https://github.com/madskjeldgaard/tree-sitter-supercollider',
    version = '2b03ff49dd19b046add072d0861c4d1ca8a384c8',
  },
  superhtml = {
    src = 'https://github.com/kristoff-it/superhtml',
    version = '8b5bb272b269afdd38cdf641c4a707dd92fbe902',
    location = 'tree-sitter-superhtml',
  },
  surface = {
    src = 'https://github.com/connorlay/tree-sitter-surface',
    version = 'f4586b35ac8548667a9aaa4eae44456c1f43d032',
  },
  svelte = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-svelte',
    version = 'ae5199db47757f785e43a14b332118a5474de1a2',
    requires = {
      'html_tags',
    },
  },
  sway = {
    src = 'https://github.com/FuelLabs/tree-sitter-sway.git',
    version = '9b7845ce06ecb38b040c3940970b4fd0adc331d1',
  },
  swift = {
    src = 'https://github.com/alex-pinkus/tree-sitter-swift',
    version = '8abb3e8b33256d89127a35e87480736f74755ff9',
    generate = true,
  },
  sxhkdrc = {
    src = 'https://github.com/RaafatTurki/tree-sitter-sxhkdrc',
    version = '440d5f913d9465c9c776a1bd92334d32febcf065',
  },
  systemtap = {
    src = 'https://github.com/ok-ryoko/tree-sitter-systemtap',
    version = 'f2b378a9af0b7e1192cff67a5fb45508c927205d',
  },
  systemverilog = {
    src = 'https://github.com/gmlarumbe/tree-sitter-systemverilog',
    version = '293928578cb27fbd0005fcc5f09c09a1e8628c89',
  },
  t32 = {
    src = 'https://github.com/xasc/tree-sitter-t32',
    version = '3bce3977303c3f88bfa9fcdfcfd1a4f8f6ffa0b0',
  },
  tablegen = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-tablegen',
    version = 'b1170880c61355aaf38fc06f4af7d3c55abdabc4',
  },
  tact = {
    src = 'https://github.com/tact-lang/tree-sitter-tact',
    version = 'a6267c2091ed432c248780cec9f8d42c8766d9ad',
  },
  tcl = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-tcl',
    version = '8f11ac7206a54ed11210491cee1e0657e2962c47',
  },
  teal = {
    src = 'https://github.com/euclidianAce/tree-sitter-teal',
    version = '05d276e737055e6f77a21335b7573c9d3c091e2f',
    generate = true,
  },
  templ = {
    src = 'https://github.com/vrischmann/tree-sitter-templ',
    version = '1c6db04effbcd7773c826bded9783cbc3061bd55',
  },
  tera = {
    src = 'https://github.com/uncenter/tree-sitter-tera',
    version = '3a38c368e806268daac9923a27e72bcafbbc16bb',
  },
  terraform = {
    src = 'https://github.com/MichaHoffmann/tree-sitter-hcl',
    version = '64ad62785d442eb4d45df3a1764962dafd5bc98b',
    location = 'dialects/terraform',
    requires = {
      'hcl',
    },
  },
  textproto = {
    src = 'https://github.com/PorterAtGoogle/tree-sitter-textproto',
    version = '568471b80fd8793d37ed01865d8c2208a9fefd1b',
  },
  thrift = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-thrift',
    version = '68fd0d80943a828d9e6f49c58a74be1e9ca142cf',
  },
  tiger = {
    src = 'https://github.com/ambroisie/tree-sitter-tiger',
    version = '4a77b2d7a004587646bddc4e854779044b6db459',
  },
  tlaplus = {
    src = 'https://github.com/tlaplus-community/tree-sitter-tlaplus',
    version = 'add40814fda369f6efd989977b2c498aaddde984',
  },
  tmux = {
    src = 'https://github.com/Freed-Wu/tree-sitter-tmux',
    version = '75d1b995b0c23400ac8e49db757a2e0386f9fa8f',
  },
  todotxt = {
    src = 'https://github.com/arnarg/tree-sitter-todotxt',
    version = '3937c5cd105ec4127448651a21aef45f52d19609',
  },
  toml = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-toml',
    version = '64b56832c2cffe41758f28e05c756a3a98d16f41',
  },
  tsv = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
    version = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
    location = 'tsv',
  },
  tsx = {
    src = 'https://github.com/tree-sitter/tree-sitter-typescript',
    version = '75b3874edb2dc714fb1fd77a32013d0f8699989f',
    location = 'tsx',
    requires = {
      'ecma',
      'jsx',
      'typescript',
    },
  },
  turtle = {
    src = 'https://github.com/GordianDziwis/tree-sitter-turtle',
    version = '7f789ea7ef765080f71a298fc96b7c957fa24422',
  },
  twig = {
    src = 'https://github.com/gbprod/tree-sitter-twig',
    version = '7195ee573ab5c3b3bb0e91b042e6f83ac1b11104',
  },
  typescript = {
    src = 'https://github.com/tree-sitter/tree-sitter-typescript',
    version = '75b3874edb2dc714fb1fd77a32013d0f8699989f',
    location = 'typescript',
    requires = {
      'ecma',
    },
  },
  typespec = {
    src = 'https://github.com/happenslol/tree-sitter-typespec',
    version = '395bef1e1eb4dd18365401642beb534e8a244056',
  },
  typoscript = {
    src = 'https://github.com/Teddytrombone/tree-sitter-typoscript',
    version = 'b5d0162b328ec52cf300054a8a23d47f84f55cb4',
  },
  typst = {
    src = 'https://github.com/uben0/tree-sitter-typst',
    version = '46cf4ded12ee974a70bf8457263b67ad7ee0379d',
  },
  udev = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-udev',
    version = '2fcb563a4d56a6b8e8c129252325fc6335e4acbf',
  },
  ungrammar = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-ungrammar',
    version = 'debd26fed283d80456ebafa33a06957b0c52e451',
  },
  unison = {
    src = 'https://github.com/kylegoetz/tree-sitter-unison',
    version = '10365cc70ab2b2de85ea7ab35cf6b7636c36ce8b',
    generate = true,
  },
  usd = {
    src = 'https://github.com/ColinKennedy/tree-sitter-usd',
    version = '4e0875f724d94d0c2ff36f9b8cb0b12f8b20d216',
  },
  uxntal = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-uxntal',
    version = 'ad9b638b914095320de85d59c49ab271603af048',
  },
  v = {
    src = 'https://github.com/vlang/v-analyzer',
    version = '095865df4b9ddd21e376d635586c663d5a736f71',
    location = 'tree_sitter_v',
  },
  vala = {
    src = 'https://github.com/vala-lang/tree-sitter-vala',
    version = '97e6db3c8c73b15a9541a458d8e797a07f588ef4',
  },
  vento = {
    src = 'https://github.com/ventojs/tree-sitter-vento',
    version = 'edd6596d4b0f392b87fc345dc26d84a6c32f7059',
  },
  vhdl = {
    src = 'https://github.com/jpt13653903/tree-sitter-vhdl',
    version = 'c2d9be3d5ab7fb2cae8ad5ae604cd3606a4af0f2',
  },
  vhs = {
    src = 'https://github.com/charmbracelet/tree-sitter-vhs',
    version = '0c6fae9d2cfc5b217bfd1fe84a7678f5917116db',
  },
  vim = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-vim',
    version = '3092fcd99eb87bbd0fc434aa03650ba58bd5b43b',
  },
  vimdoc = {
    src = 'https://github.com/neovim/tree-sitter-vimdoc',
    version = 'f061895a0eff1d5b90e4fb60d21d87be3267031a',
  },
  vrl = {
    src = 'https://github.com/belltoy/tree-sitter-vrl',
    version = '274b3ce63f72aa8ffea18e7fc280d3062d28f0ba',
  },
  vue = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-vue',
    version = 'ce8011a414fdf8091f4e4071752efc376f4afb08',
    requires = {
      'html_tags',
    },
  },
  wgsl = {
    src = 'https://github.com/szebniok/tree-sitter-wgsl',
    version = '40259f3c77ea856841a4e0c4c807705f3e4a2b65',
  },
  wgsl_bevy = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-wgsl-bevy',
    version = 'd9306a798ede627001a8e5752f775858c8edd7e4',
  },
  wing = {
    src = 'https://github.com/winglang/tree-sitter-wing',
    version = '76e0c25844a66ebc6e866d690fcc5f4e90698947',
  },
  wit = {
    src = 'https://github.com/bytecodealliance/tree-sitter-wit',
    version = 'v1.3.0',
  },
  wxml = {
    src = 'https://github.com/BlockLune/tree-sitter-wxml',
    version = '7b821c748dc410332f59496c0dea2632168c4e5a',
  },
  xcompose = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-xcompose',
    version = 'a51d6366f041dbefec4da39a7eb3168a9b1cbc0e',
  },
  xml = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-xml',
    version = '5000ae8f22d11fbe93939b05c1e37cf21117162d',
    location = 'xml',
    requires = {
      'dtd',
    },
  },
  xresources = {
    src = 'https://github.com/ValdezFOmar/tree-sitter-xresources',
    version = 'v1.0.0',
  },
  yaml = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-yaml',
    version = '4463985dfccc640f3d6991e3396a2047610cf5f8',
  },
  yang = {
    src = 'https://github.com/Hubro/tree-sitter-yang',
    version = '2c0e6be8dd4dcb961c345fa35c309ad4f5bd3502',
  },
  yuck = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-yuck',
    version = '6c60112b3b3e739fb1ca4a8ea4bea2b6ffe11318',
  },
  zathurarc = {
    src = 'https://github.com/Freed-Wu/tree-sitter-zathurarc',
    version = '0554b4a5d313244b7fc000cbb41c04afae4f4e31',
  },
  zig = {
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-zig',
    version = '6479aa13f32f701c383083d8b28360ebd682fb7d',
  },
  ziggy = {
    src = 'https://github.com/kristoff-it/ziggy',
    version = '4353b20ef2ac750e35c6d68e4eb2a07c2d7cf901',
    location = 'tree-sitter-ziggy',
  },
  ziggy_schema = {
    src = 'https://github.com/kristoff-it/ziggy',
    version = '4353b20ef2ac750e35c6d68e4eb2a07c2d7cf901',
    location = 'tree-sitter-ziggy-schema',
  },
  zsh = {
    src = 'https://github.com/georgeharker/tree-sitter-zsh',
    version = 'bd344c23a7683e293d077c6648e88f209782fedb',
  },
}

local function append_selected(result, seen, visiting, name)
  vim.validate('name', name, 'string')

  if seen[name] then
    return
  end
  if visiting[name] then
    error(('parser dependency cycle includes `%s`'):format(name), 0)
  end

  local parser = M.registry[name]
  if not parser then
    error(('unknown parser `%s`'):format(name), 0)
  end

  visiting[name] = true
  for _, dependency in ipairs(parser.requires or {}) do
    append_selected(result, seen, visiting, dependency)
  end
  visiting[name] = nil
  seen[name] = true

  if not parser.src then
    return
  end

  local selected = vim.deepcopy(parser)
  selected.name = name
  selected.requires = nil
  result[#result + 1] = selected
end

function M.select(names)
  require('ts-pack.spec').assert_list('names', names)

  local result = {}
  local seen = {}
  for _, name in ipairs(names) do
    append_selected(result, seen, {}, name)
  end
  return result
end

return M
