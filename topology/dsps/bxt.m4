#
# Broxton differentiation for pipelines and components
#

# Low Latency PCM Configuration
SectionVendorTuples."pipe_ll_schedule_plat_tokens" {
	tokens "sof_sched_tokens"

	tuples."word" {
		SOF_TKN_SCHED_PRIORITY 	"0"
		SOF_TKN_SCHED_MIPS 	"50000"
	}
}

SectionData."pipe_ll_schedule_plat" {
	tuples "pipe_ll_schedule_plat_tokens"
}

# Media PCM Configuration
SectionVendorTuples."pipe_media_schedule_plat_tokens" {
	tokens "sof_sched_tokens"

	tuples."word" {
		SOF_TKN_SCHED_PRIORITY 	"1"
		SOF_TKN_SCHED_MIPS 	"100000"
	}
}

SectionData."pipe_media_schedule_plat" {
	tuples "pipe_media_schedule_plat_tokens"
}

# Tone Signal Generator Configuration
SectionVendorTuples."pipe_tone_schedule_plat_tokens" {
	tokens "sof_sched_tokens"

	tuples."word" {
		SOF_TKN_SCHED_PRIORITY 	"2"
		SOF_TKN_SCHED_MIPS 	"200000"
	}
}

SectionData."pipe_tone_schedule_plat" {
	tuples "pipe_tone_schedule_plat_tokens"
}

# DAI0 platform playback configuration
SectionVendorTuples."dai0p_plat_tokens" {
	tokens "sof_dai_tokens"

	tuples."word" {
		SOF_TKN_DAI_DMAC 	"1"
		SOF_TKN_DAI_DMAC_CHAN 	"0"
	}
}

SectionData."dai0p_plat_conf" {
	tuples "dai0p_plat_tokens"
}

# DAI0 platform capture configuration
SectionVendorTuples."dai0c_plat_tokens" {
	tokens "sof_dai_tokens"

	tuples."word" {
		SOF_TKN_DAI_DMAC 	"1"
		SOF_TKN_DAI_DMAC_CHAN 	"1"
	}
}

SectionData."dai0c_plat_conf" {
	tuples "dai0c_plat_tokens"
}
