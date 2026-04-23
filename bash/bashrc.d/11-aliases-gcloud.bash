# ==============================================================================
# 11-aliases-gcloud.bash — Google Cloud SDK aliases
# ==============================================================================

alias gc_update='gcloud components update'
alias gc_auth='gcloud auth login; gcloud auth application-default login'
alias gc_authList='gcloud auth list'

# Uncomment to enable:
# alias gc_authLogin='gcloud auth login'
# alias gc_authADC='gcloud auth application-default login'
# alias gc_set_projDev='gcloud config set project aeo-hr-datamart-dev'
# alias gc_set_projProd='gcloud config set project aeo-hr-datamart-prod'
# alias gc_set_projDataEngDev='gcloud config set project aeo-data-engineering-dev'
# alias gc_get_projId='gcloud config get-value project'
# alias gc_get_jobInfo='bq ls --jobs=true --format=json | jq "."'
