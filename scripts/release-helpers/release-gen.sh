#!/bin/bash
set -e

# This script helps in preparing for a new release by updating all the necessary
# files with the new versions and create new artifacts that are checked into the
# repo.

echo "Preparing for a new release"
echo

NEW_VERSION=$1

if [ "$NEW_VERSION" == "" ]; then
    echo "NEW_VERSION not set."
    echo "Set NEW_VERSION and run again."
    exit 1
fi

# Warning header to be added to all the generated files.
FILE_HEADER_NOTE="# Do not edit this file manually. Use release-gen.sh script to update."

# These files contain the current versions.
COMMUNITY_CHANGES_FILE=deploy/olm/community-changes.yaml
RHEL_CHANGES_FILE=deploy/olm/rhel-changes.yaml

# Get previous versions from community hub and rhel changes file.
PREV_VERSION_COMMUNITY=$(yq r $COMMUNITY_CHANGES_FILE [spec.version])
PREV_VERSION_RHEL=$(yq r $RHEL_CHANGES_FILE [spec.version])

# Ensure that the pervious versions are the same before proceeding.
if [ "$PREV_VERSION_COMMUNITY" != "$PREV_VERSION_RHEL" ]; then
    echo "$COMMUNITY_CHANGES_FILE and $RHEL_CHANGES_FILE have different version numbers."
    echo "Unable to decide previous version number. Please resolve the conflicting versions and run again."
    exit 1
fi

PREV_VERSION=$PREV_VERSION_COMMUNITY

# Ensure that the new version is not the same as the previous version.
if [ "$NEW_VERSION" == "$PREV_VERSION" ]; then
    echo "New Version($NEW_VERSION) and Previous Version($PREV_VERSION) are the same."
    echo "Use a different version and run again."
    exit 1
fi

echo "Current version: $PREV_VERSION"
echo "New version: $NEW_VERSION"
echo

# Community changes update
echo "Updating $COMMUNITY_CHANGES_FILE..."

# Community operator changes template.
cat << EOF >$COMMUNITY_CHANGES_FILE
$FILE_HEADER_NOTE
metadata.name: storageosoperator.v$NEW_VERSION
metadata.namespace: placeholder
metadata.annotations.containerImage: storageos/cluster-operator:$NEW_VERSION
spec.version: $NEW_VERSION
spec.install.spec.deployments[0].spec.template.spec.containers[0].image: storageos/cluster-operator:$NEW_VERSION
spec.replaces: storageosoperator.v$PREV_VERSION
EOF
echo


# rhel changes update
echo "Updating $RHEL_CHANGES_FILE..."

# RHEL operator changes template.
# This provides more control over the values in the example.
cat << EOF >$RHEL_CHANGES_FILE
$FILE_HEADER_NOTE
metadata.name: storageosoperator.v$NEW_VERSION
metadata.namespace: placeholder
metadata.annotations.containerImage: registry.connect.redhat.com/storageos/cluster-operator:$NEW_VERSION
metadata.annotations.certified: "true"
metadata.annotations.alm-examples: |-
  [
    {
      "apiVersion": "storageos.com/v1",
      "kind": "StorageOSCluster",
      "metadata": {
        "name": "example-storageos",
        "namespace": "default"
      },
      "spec": {
        "namespace": "kube-system",
        "secretRefName": "storageos-api",
        "secretRefNamespace": "default"
      }
    },
    {
      "apiVersion": "storageos.com/v1",
      "kind": "Job",
      "metadata": {
        "name": "example-job",
        "namespace": "default"
      },
      "spec": {
        "image": "registry.connect.redhat.com/storageos/cluster-operator:latest",
        "args": ["/var/lib/storageos"],
        "mountPath": "/var/lib",
        "hostPath": "/var/lib",
        "completionWord": "done"
      }
    },
    {
      "apiVersion": "storageos.com/v1",
      "kind": "StorageOSUpgrade",
      "metadata": {
        "name": "example-upgrade",
        "namespace": "default"
      },
      "spec": {
        "newImage": "registry.connect.redhat.com/storageos/node:latest"
      }
    }
  ]

spec.version: $NEW_VERSION
spec.install.spec.deployments[0].spec.template.spec.containers[0].image: registry.connect.redhat.com/storageos/cluster-operator:$NEW_VERSION
spec.customresourcedefinitions.owned[2].specDescriptors[0].description: The StorageOS Node image to upgrade to. e.g. \`registry.connect.redhat.com/storageos/node:latest\`
spec.replaces: storageosoperator.v$PREV_VERSION
EOF
echo


# Package changes update
PACKAGE_CHANGES_FILE=deploy/olm/package-changes.yaml

echo "Updating $PACKAGE_CHANGES_FILE..."

# OLM package file template.
cat << EOF >$PACKAGE_CHANGES_FILE
$FILE_HEADER_NOTE
channels[0].currentCSV: storageosoperator.v$1
EOF
echo


# Update creation date of the CSV in configmap.
echo "Updating createdAt timestamp..."
sed -i -e "s/createdAt.*/createdAt: $(date -u +'%Y-%m-%dT%H:%M:%SZ')/g" deploy/storageos-operators.configmap.yaml

echo "Updating container image labels..."
# Update operator version.
sed -i -e "s/version.*/version=\"$NEW_VERSION\" \\\/g" build/Dockerfile build/rhel-build-service/Dockerfile

# Update all the metadata files with above changes.
echo "Updating all the metadata files..."
bash scripts/metadata-checker/update-metadata-files.sh

# Create versioned CSV files.
echo "Creating versioned CSV files..."
cp deploy/olm/storageos/storageos.clusterserviceversion.yaml deploy/olm/storageos/storageos.v$NEW_VERSION.clusterserviceversion.yaml
cp deploy/olm/csv-rhel/storageos.clusterserviceversion.yaml deploy/olm/csv-rhel/storageos.v$NEW_VERSION.clusterserviceversion.yaml

echo "Ready for new release."
