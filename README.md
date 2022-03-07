# borgmatic-config-hardcopy

Print borgmatic configuration and ssh key as a hardcopy (also as QR code), on two pages.

## Disclaimer

I wrote this script for my personal use, to facilitate printing last-ditch physical backup of borg repository information. As stated in the license, there is absolutely no warranty of any kind, use at your own risk. **Always look at the output and test recovery from the QR code**.

## How it works

1. Removes comments from your Borgmatic `config.yaml` (to minify).
2. Copies your SSH private key.
3. Compresses the above as a `tar.gz` archive, printed as a QR code.
4. Formats everything as a two-sided LaTeX document, with minimal recovery instructions.

## Installation

Just clone the repository, and install

1. `bash` and `tar`.
2. a working `pdflatex`, with packages `geometry`, `underscore`, `verbatim`, `graphicx`, `datetime2` available
3. `qrencode`
4. [`yq`](https://mikefarah.github.io/yq/) for stripping comments from YAML

On a relatively recent Ubuntu/Debian (2021 and later) the following should be sufficient (assuming you have `bash` and `tar`):

```
apt-get install texlive-latex-base texlive-latex-recommended texlive-latex-extra qrencode
snap install yq
```

## Recovery

You can retype the printed information, or scan the QR code (as binary).

## Similar software

This particular project is very *specific* (backup borgmatic recovery information) and *lightweight*. More generic alternatives include

1. [paperbackup](https://github.com/intra2net/paperbackup)
2. [paperkey](https://www.jabberwocky.com/software/paperkey/)
3. [qr-backup](https://github.com/za3k/qr-backup)
