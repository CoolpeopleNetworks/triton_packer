# Note: This makefile assumes the triton environment has been set up
#       by the triton CLI using 'eval "$(triton env)"'
export PKR_VAR_triton_account=$(SDC_ACCOUNT)
export PKR_VAR_triton_key_id=$(SDC_KEY_ID)
export PKR_VAR_triton_url=$(SDC_URL)

.PHONY: debian-9-cloudinit postgresql12-patroni
all:

debian-9-cloudinit:
	packer init debian-9-cloudinit.pkr.hcl
	packer build -force -var "image_version=20210815" debian-9-cloudinit.pkr.hcl 

postgresql12-patroni:
	packer init postgresql12-patroni.pkr.hcl
	packer build -force -var "image_version=20210815" postgresql12-patroni.pkr.hcl
