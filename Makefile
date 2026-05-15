.PHONY: deploy deploy-operator deploy-openmrs deps

## deploy: Install operators then OpenMRS (full stack, use for fresh installs)
deploy: deploy-operator deploy-openmrs

## deploy-operator: Install cluster operators (MariaDB, etc.) into mariadb-system
deploy-operator:
	helm dependency update ./helm/openmrs-operator
	helm upgrade --install openmrs-operator ./helm/openmrs-operator \
	  --namespace mariadb-system \
	  --create-namespace \
	  --wait

## deploy-openmrs: Install OpenMRS app stack (operator must already be running)
deploy-openmrs:
	helm dependency update ./helm/openmrs
	helm upgrade --install openmrs ./helm/openmrs \
	  --namespace openmrs \
	  --create-namespace \
	  --values ./helm/kind-openmrs.yaml \
	  --wait

## deps: Update all subchart dependencies (run after editing any subchart)
deps:
	helm dependency update ./helm/openmrs-backend
	helm dependency update ./helm/openmrs-operator
	helm dependency update ./helm/openmrs
