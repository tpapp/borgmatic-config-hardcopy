#!/bin/bash

# Print borgmatic configuration and ssh key as a hardcopy

set -e                          # stop on error

# defaults
SSHKEY=~/.ssh/id_ed25519
BORGMATIC_CONFIG=~/.config/borgmatic.d/config.yaml
ID=$(hostname)
OUTPUT="borgmatic-config-print.pdf"
FORCE=false

usage () {
    cat <<EOF 
Usage:
        $0 -o output -s sshkey -c borgmatic_config -d id -h

Optional arguments (with defaults)

-o ${OUTPUT}
   output file, will abort if already exists unless -f

-f
   force overwriting output file

-s ${SSHKEY}
   location of SSH private key

-c ${BORGMATIC_CONFIG}
   config.yaml for borgmatic

-d ${ID}
   will be printed as a subtitle (defaults to hostname)

-h
   print this help
EOF
}

while getopts "o:s:c:i:hf" OPTIONS; do
    case "${OPTIONS}" in
        o)
            OUTPUT=${OPTARG}
            ;;
        s)
            SSHKEY=${OPTARG}
            ;;
        c)
            BORGMATIC_CONFIG=${OPTARG}
            ;;
        i)
            ID=${OPTARG}
            ;;
        f)
            FORCE=true
            ;;
        h)
            echo -e "Generate a PDF file for printing a borgmatic configuration and the ssh key on paper.\n"
            usage
            exit 0
            ;;
        :)
            echo "Error: -${OPTARG} requires an argument."
            usage
            exit 1
            ;;
        *)
            echo "Unrecognized options."
            usage
            exit 1
            ;;
    esac
done

if [ -f "${OUTPUT}" ] ; then
    if ${FORCE}; then
       echo "Output file ${OUTPUT} already exists, overwriting."
    else
       echo "Output file ${OUTPUT} already exists, aborting."
       exit 1
    fi
fi

if ! [ -s "${SSHKEY}" ] ; then
    echo "SSH key ${SSHKEY} missing or empty, aborting."
    exit 1
fi

if ! [ -s "${BORGMATIC_CONFIG}" ] ; then
    echo "Borgmatic config ${BORGMATIC_CONFIG} missing or empty, aborting."
    exit 1
fi

cat <<EOF
Collecting borgmatic configuration for printing into ${OUTPUT}.

SSH key: ${SSHKEY}
ID: ${ID}
Borgmatic config file: ${BORGMATIC_CONFIG}
EOF

# setup
TMP=$(mktemp -d)
TEX=$TMP/page.tex
SSHFILE=$(basename ${SSHKEY})
DIR=${PWD}                      # save directory

# copy ssh key
cp ${SSHKEY} ${TMP}

# strip YAML
cat ${BORGMATIC_CONFIG} | yq '... comments=""' > ${TMP}/config.yaml

# make QR code
cd ${TMP}
tar -cvzO config.yaml ${SSHFILE} | qrencode -8 -l Q -t eps -o ${TMP}/qr.eps

# make LaTeX source
cat <<EOF > ${TEX}
\documentclass[a4paper,10pt]{article}
\usepackage[margin=2cm]{geometry}
\newcommand{\UnderscoreCommands}{\do\verbatiminput}
\usepackage[strings]{underscore}
\usepackage{verbatim}
\usepackage{graphicx}
\usepackage{datetime2}
\begin{document}
\begin{center}
\Large{Borgmatic configuration hardcopy for ${ID}}\\\\
\large{\DTMnow}
\end{center}
\paragraph{SSH key file \texttt{${SSHFILE}}}
\verbatiminput{${SSHFILE}}
\paragraph{Borgmatic configuration}
\verbatiminput{config.yaml}
\newpage
\paragraph{The above as machine-readable binary}
Recovery example:
\begin{enumerate}
\item take a photo or scan, save as \verb!qr.png!
\item decode with \verb!zbarimg --raw -Sbinary -1 qr.png > qr.tar.gz!\\\\\textbf{(note: requires zbarimg 0.23.1 or higher)}
\item extract with \verb!tar -zxvf qr.tar.gz!
\end{enumerate}
\includegraphics[width=\textwidth]{qr.eps}
\end{document}
EOF

# compile LaTeX source
pdflatex -interaction=batchmode page.tex >/dev/null
echo "Output saved in ${OUTPUT}"
cd ${DIR}
cp ${TMP}/page.pdf ${OUTPUT}

# cleanup tmp
rm -Rf ${TMP}
