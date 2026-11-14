# Builds the web app and publishes it to GitHub Pages (the gh-pages branch).
#
# Usage, from the project folder:
#   ./tool/deploy_web.ps1
#
# Needs env.json (your Supabase URL + publishable key). The publishable key
# ends up in the public JavaScript, which is what Supabase designed it for:
# Row Level Security in supabase/schema.sql decides what visitors may do.

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

if (-not (Test-Path env.json)) {
  throw 'env.json is missing. Copy env.example.json to env.json and add your Supabase keys first.'
}

$remote = git remote get-url origin
$repoName = (($remote -split '/')[-1]) -replace '\.git$', ''
$source = git rev-parse --short HEAD

# GitHub Pages serves a project site from /<repo-name>/, so the app must
# load its files from there.
flutter build web --release --base-href "/$repoName/" --dart-define-from-file=env.json
if ($LASTEXITCODE -ne 0) { throw 'flutter build web failed' }

$out = Join-Path ([IO.Path]::GetTempPath()) 'facet-gh-pages'
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
Copy-Item -Recurse build/web $out
# Stop GitHub's Jekyll step from skipping any files.
New-Item -ItemType File (Join-Path $out '.nojekyll') | Out-Null

Push-Location $out
try {
  git init -q -b gh-pages
  git add -A
  git commit -q -m "Deploy web build of $source"
  if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
  # gh-pages only ever holds the latest build, so replacing it is intended.
  git push -f $remote gh-pages
  if ($LASTEXITCODE -ne 0) { throw 'git push failed' }
} finally {
  Pop-Location
}

$owner = ($remote -split '/')[-2]
Write-Host "Deployed. Live in a minute at https://$($owner.ToLower()).github.io/$repoName/"
