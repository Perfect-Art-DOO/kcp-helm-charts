# Exit on error.
set -e

# Setup logger.
ERROR_STYLE=`tput setaf 1`
INFO_STYLE=`tput setaf 2`
BOLD_STYLE=`tput bold`
RESET_STYLE=`tput sgr0`

function say { echo -e "${INFO_STYLE}${BOLD_STYLE}$@${RESET_STYLE}"; }
function saye { echo -e "${ERROR_STYLE}${BOLD_STYLE}$@${RESET_STYLE}"; }

function release-helm-chart {
  if [ -n "$(git status --porcelain)" ]; then
    saye "\nGit working tree not clean, aborting."
    exit 1
  fi
  say "\nGenerating Helm Chart package for new version."
  say "Please note that your gh-pages branch, if it locally exists, should be up-to-date."
  helm repo add stable https://charts.helm.sh/stable/
  helm dependency build .
  helm package .
  rm -rf "./charts/"
  say "\nSwitching git branch to gh-pages so that we can commit package along the previous versions."
  git checkout gh-pages
  say "\nGenerating new Helm index, containing all existing versions in gh-pages (previous ones + new one)."
  helm repo index . --merge index.yaml
  say "\nCommit new package and index."
  git add -A "./zally-*.tgz" ./index.yaml && git commit -m "Update Helm repository from CI."
  say "\nIf you are happy with the changes, please manually push to the gh-pages branch. No force should be needed."
  say "Assuming upstream is your remote, please run: git push upstream gh-pages."
}

# Execute script.
release-helm-chart