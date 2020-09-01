package v1

// ClusterPhase is the phase of the storageos cluster at a given point in time.
type ClusterPhase string

// Constants for operator defaults values and different phases.
const (
	ClusterPhaseInitial ClusterPhase = ""
	// A cluster is in running phase when the cluster health is reported
	// healthy, all the StorageOS nodes are ready.
	ClusterPhaseRunning ClusterPhase = "Running"
	// A cluster is in creating phase when the cluster resource provisioning as
	// started
	ClusterPhaseCreating ClusterPhase = "Creating"
	// A cluster is in pending phase when the creation hasn't started. This can
	// happen if there's an existing cluster and the new cluster provisioning is
	// not allowed by the operator.
	ClusterPhasePending ClusterPhase = "Pending"
	// A cluster is in terminating phase when the cluster delete is initiated.
	// The cluster object is waiting for the finalizers to be executed.
	ClusterPhaseTerminating ClusterPhase = "Terminating"
)
