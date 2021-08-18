# Note: This makefile assumes the triton environment has been set up
#       by the triton CLI using 'eval "$(triton env)"'
export PKR_VAR_triton_account=$(SDC_ACCOUNT)
export PKR_VAR_triton_key_id=$(SDC_KEY_ID)
export PKR_VAR_triton_url=$(SDC_URL)

.PHONY: debian-9-cloudinit fabio postgresql12-patroni-consul
all:

debian-9-cloudinit:
	packer init debian-9-cloudinit.pkr.hcl
	packer build -force -var "image_version=20210815" debian-9-cloudinit.pkr.hcl 

fabio:
	packer init fabio.pkr.hcl
	packer build -force -var "image_version=1.5.15" fabio.pkr.hcl 

postgresql12-patroni-consul:
	packer init postgresql12-patroni-consul.pkr.hcl
	packer build -force -var "image_version=20210815" postgresql12-patroni-consul.pkr.hcl
