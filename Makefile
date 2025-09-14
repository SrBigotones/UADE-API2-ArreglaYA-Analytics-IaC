TF=terraform
PLAN_FILE=tfplan.out

.PHONY: init plan apply destroy clean

init:
	$(TF) init

plan:
	$(TF) plan -out=$(PLAN_FILE)

apply:
	$(TF) apply "$(PLAN_FILE)"

destroy:
	$(TF) destroy -auto-approve

clean:
	rm -f $(PLAN_FILE) plan.log