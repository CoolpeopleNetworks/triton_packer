# Note: This makefile assumes the triton environment has been set up
#       by the triton CLI using 'eval "$(triton env)"'
export PKR_VAR_triton_account=$(SDC_ACCOUNT)
export PKR_VAR_triton_key_id=$(SDC_KEY_ID)
export PKR_VAR_triton_url=$(SDC_URL)

all:

debian-9-cloudinit:
	packer init debian-9-cloudinit.pkr.hcl
	packer build -force debian-9-cloudinit.pkr.hcl
