# mdScriptFilter

mdScriptFilter is a command-line tool to search the macOS [Spotlight](https://en.wikipedia.org/wiki/Spotlight_(Apple)) database, similar to `mdfind`, and return JSON suitable for [Alfred](https://www.alfred.com/)’s [Script Filter Input](https://www.alfredapp.com/help/workflows/inputs/script-filter/) and [Grid View](https://www.alfredapp.com/help/workflows/user-interface/grid/).

## Installation

Download the [latest release](https://github.com/vitorgalvao/mdscriptfilter/releases/latest) and include it in your Alfred workflow. The executable is signed and notarised.

## Usage

Queries in mdScriptFilter use the same syntax as metadata queries in `mdfind`. Run `mdscriptfilter --help` to see available options and defaults.

A couple of examples of doing the same search with both tools:

### Finding Screenshots on the Desktop

```shell
mdfind 'kMDItemIsScreenCapture == 1' -onlyin ~/Desktop
```

```shell
mdscriptfilter 'kMDItemIsScreenCapture == 1' --positive-scope ~/Desktop
```

### Finding PDFs with Specific Text

```shell
mdfind 'kMDItemTextContent == "fruits and vegetables" && kMDItemContentType == "com.adobe.pdf"'
```

```shell
mdscriptfilter 'kMDItemTextContent == "fruits and vegetables" && kMDItemContentType == "com.adobe.pdf"'
```

## Build

Use the build in the releases if you want to use mdScripFilter in a workflow. To build it yourself for development:

```shell
# Clone the repository
git clone git@github.com:vitorgalvao/mdscriptfilter.git

# Change to directory
cd mdscriptfilter

# Build
swift build --configuration release --arch arm64 --arch x86_64
```

The output binary will be in the same directory, under `.build/apple/Products/Release`.

## License

3-Clause BSD
