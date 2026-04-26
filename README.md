# XLSXasJSON
![LICENSE MIT](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square)
[![Run tests](https://github.com/YongHee-Kim/XLSXasJSON.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/YongHee-Kim/XLSXasJSON.jl/actions/workflows/CI.yml)
[![Converage](https://github.com/YongHee-Kim/XLSXasJSON.jl/blob/gh-pages/dev/coverage/badge_linecoverage.svg)](https://YongHee-Kim.github.io/XLSXasJSON.jl/dev/coverage/index.html)

**Documentation**: [Docs](https://yonghee-kim.github.io/XLSXasJSON.jl/dev/)
<!-- [![][docs-latest-img]][docs-latest-url] -->


## Acknowledgement
Portions of this project were developed with the support of [Devsisters Corp.](https://github.com/Devsisters).  And and were inspired by the design of [excel-as-json](https://github.com/stevetarver/excel-as-json)

## Usage
Parse .xlsx files into Julia data structures and serializes them as JSON-encoded files.

Designated row or colum must be standardized [JSONPointer](https://tools.ietf.org/html/rfc6901) tokens. All remaining rows are then converted and included in the JSON output.

## Installation

```julia
pkg> add XLSXasJSON
```

## Acknowledgement
The initial version of XLSXasJSON.jl was developed with the support from [Devsisters Corp.](https://github.com/Devsisters). And inspired by the design of [excel-as-json](https://github.com/stevetarver/excel-as-json)

