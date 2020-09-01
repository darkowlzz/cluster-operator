/*


Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"

	"github.com/go-logr/logr"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"

	storageoscomv1 "github.com/storageos/cluster-operator/api/v1"
)

// StorageOSClusterReconciler reconciles a StorageOSCluster object
type StorageOSClusterReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=storageos.com,resources=storageosclusters,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=storageos.com,resources=storageosclusters/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=apps,resources=statefulsets;daemonsets;deployments;replicasets,verbs=*
// +kubebuilder:rbac:groups="",resources=nodes,verbs=get;list;watch;create;update;patch
// +kubebuilder:rbac:groups="",resources=pods;pods/binding;pods/status,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups="",resources=events;namespaces;serviceaccounts;secrets;services;services/finalizers;persistentvolumeclaims;persistentvolumeclaims/status;persistentvolumes;configmaps;replicationcontrollers;endpoints,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=rbac.authorization.k8s.io,resources=roles;rolebindings;clusterroles;clusterrolebindings,verbs=create;delete
// +kubebuilder:rbac:groups=storage.k8s.io,resources=storageclasses;volumeattachments;csinodeinfos;csinodes;csidrivers,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=apiextensions.k8s.io,resources=customresourcedefinitions,verbs=create;delete
// +kubebuilder:rbac:groups=csi.storage.k8s.io,resources=csidrivers,verbs=create;delete
// +kubebuilder:rbac:groups=policy,resources=poddisruptionbudgets,verbs=list;watch
// +kubebuilder:rbac:groups=security.openshift.io,resourceNames=privileged,resources=securitycontextconstraints,verbs=create;delete;update;get;use
// +kubebuilder:rbac:groups=admissionregistration.k8s.io,resources=mutatingwebhookconfigurations,verbs=*
// +kubebuilder:rbac:groups=monitoring.coreos.com,resources=servicemonitors,verbs=*
// +kubebuilder:rbac:groups=apps,resourceNames=storageos-cluster-operator,resources=deployments/finalizers,verbs=update
// +kubebuilder:rbac:groups=events.k8s.io,resources=events,verbs=create;patch
// +kubebuilder:rbac:groups=coordination.k8s.io,resources=leases,verbs=get;create;update

func (r *StorageOSClusterReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	_ = context.Background()
	_ = r.Log.WithValues("storageoscluster", req.NamespacedName)

	// your logic here

	return ctrl.Result{}, nil
}

func (r *StorageOSClusterReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&storageoscomv1.StorageOSCluster{}).
		Complete(r)
}
