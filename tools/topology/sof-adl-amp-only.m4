#
`# Topology for Alderlake with 'AMP` amp + 4 HDMI without headphone codec'
#

# Include topology builder
include(`utils.m4')
include(`dai.m4')
include(`pipeline.m4')
include(`ssp.m4')
include(`muxdemux.m4')
include(`hda.m4')

# Include TLV library
include(`common/tlv.m4')

# Include Token library
include(`sof/tokens.m4')

# Include Tigerlake DSP configuration
include(`platform/intel/'PLATFORM`.m4')
include(`platform/intel/dmic.m4')
DEBUG_START

#
# Define the demux configure
#
dnl Configure demux
dnl name, pipeline_id, routing_matrix_rows
dnl Diagonal 1's in routing matrix mean that every input channel is
dnl copied to corresponding output channels in all output streams.
dnl I.e. row index is the input channel, 1 means it is copied to
dnl corresponding output channel (column index), 0 means it is discarded.
dnl There's a separate matrix for all outputs.
define(matrix1, `ROUTE_MATRIX(1,
			     `BITS_TO_BYTE(1, 0, 0 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 1, 0 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 1 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,1 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,1 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,1 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,0 ,1 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,0 ,0 ,1)')')

define(matrix2, `ROUTE_MATRIX(9,
			     `BITS_TO_BYTE(1, 0, 0 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 1, 0 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 1 ,0 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,1 ,0 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,1 ,0 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,1 ,0 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,0 ,1 ,0)',
			     `BITS_TO_BYTE(0, 0, 0 ,0 ,0 ,0 ,0 ,1)')')

ifelse(
	AMP_TYPE, `DUMB', `
	dnl name, num_streams, route_matrix list
	MUXDEMUX_CONFIG(demux_priv_1, 2, LIST_NONEWLINE(`', `matrix1,', `matrix2'))',
	)

#
# Define the pipelines
#
# 1. dumb amp
`#   PCM0 --> volume --> demux --> SSP'AMP_SSP` (Speaker - CODEC)'
#                         |
#   PCM6 <----------------+
# 2. smart amp
`#   PCM1 <---> volume <----> SSP'AMP_SSP` (Speaker - CODEC)'
#
# PCM2 ----> volume -----> iDisp1
# PCM3 ----> volume -----> iDisp2
# PCM4 ----> volume -----> iDisp3
# PCM5 ----> volume -----> iDisp4
# PCM99 <---- volume <---- DMIC01 (dmic 48k capture)
# PCM100 <---- kpb <---- DMIC16K (dmic 16k capture)
#
# Mapping between PCM the pipeline id
#
# 1. dumb amp
#   PCM0: pipe 1
#   PCM6: pipe 9
# 2. smart amp
#   PCM1: pipe 2/3
#
# PCM2: pipe 5
# PCM3: pipe 6
# PCM4: pipe 7
# PCM5: pipe 8
# PCM99: pipe 10
# PCM100: pipe 11/12
#
# List of backend dai link id
#
# 0/1:     DMIC01/DMIC16K
# 2/3/4/5: iDisp1/iDisp2/iDisp3/iDisp4
`# 6:       SSP'AMP_SSP`'
#

ifdef(`AMP_SSP',`',`fatal_error(note: Define AMP_SSP for speaker amp SSP Index)')
# Speaker related
# SSP related
# define speaker SSP index
define(`SPK_SSP_INDEX', AMP_SSP)
# define SSP BE dai_link name
define(`SPK_SSP_NAME', concat(concat(`SSP', SPK_SSP_INDEX),`-Codec'))
# define BE dai_link ID
define(`SPK_BE_ID', 6)
# Ref capture related
# Ref capture BE dai_name
define(`SPK_REF_DAI_NAME', concat(concat(`SSP', SPK_SSP_INDEX),`.IN'))

# Define pipeline id for intel-generic-dmic-kwd.m4
# to generate dmic setting with kwd when we have dmic
# define channel
define(CHANNELS, `4')
# define kfbm with volume
define(KFBM_TYPE, `vol-kfbm')
# define pcm, pipeline and dai id
define(DMIC_PCM_48k_ID, `99')
define(DMIC_PIPELINE_48k_ID, `10')
define(DMIC_DAI_LINK_48k_ID, `0')
define(DMIC_PCM_16k_ID, `100')
define(DMIC_PIPELINE_16k_ID, `11')
define(DMIC_PIPELINE_KWD_ID, `12')
define(DMIC_DAI_LINK_16k_ID, `1')
# define pcm, pipeline and dai id
define(KWD_PIPE_SCH_DEADLINE_US, 5000)

# include the generic dmic with kwd
include(`platform/intel/intel-generic-dmic-kwd.m4')

dnl PIPELINE_PCM_ADD(pipeline,
dnl     pipe id, pcm, max channels, format,
dnl     frames, deadline, priority, core)

ifelse(
	AMP_TYPE, `DUMB', `
	# Low Latency playback pipeline 1 on PCM 0 using max 2 channels of s24le.
	# Schedule 48 frames per 1000us deadline with priority 0 on core 0
	PIPELINE_PCM_ADD(
		sof/pipe-volume-demux-playback.m4,
		1, 0, 2, s32le,
		1000, 0, 0,
		48000, 48000, 48000)',
	AMP_TYPE, `SMART', `
	# Low Latency playback pipeline 2 on PCM 1 using max 2 channels of s24le.
	# Schedule 48 frames per 1000us deadline with priority 0 on core 0
	PIPELINE_PCM_ADD(
		sof/pipe-volume-playback.m4,
		2, 1, 2, s32le,
		1000, 0, 0,
		48000, 48000, 48000)

	# Low Latency capture pipeline 3 on PCM 1 using max 2 channels of s24le.
	# Schedule 48 frames per 1000us deadline with priority 0 on core 0
	PIPELINE_PCM_ADD(sof/pipe-volume-capture.m4,
		3, 1, 2, s32le,
		1000, 0, 0,
		48000, 48000, 48000)',
	)

# Low Latency playback pipeline 2 on PCM 2 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-volume-playback.m4,
	5, 2, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)

# Low Latency playback pipeline 3 on PCM 3 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-volume-playback.m4,
	6, 3, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)

# Low Latency playback pipeline 4 on PCM 4 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-volume-playback.m4,
	7, 4, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)

# Low Latency playback pipeline 5 on PCM 5 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-volume-playback.m4,
	8, 5, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)

# DAIs configuration
#

dnl DAI_ADD(pipeline,
dnl     pipe id, dai type, dai_index, dai_be,
dnl     buffer, periods, format,
dnl     frames, deadline, priority, core)

ifelse(
	AMP_TYPE, `DUMB', `
`	# playback DAI is SSP'AMP_SSP` using 2 periods'
`	# Buffers use 'AMP_FMT` format, with 48 frame per 1000us on core 0 with priority 0'
	DAI_ADD(sof/pipe-dai-playback.m4,
		1, SSP, SPK_SSP_INDEX, SPK_SSP_NAME,
		PIPELINE_SOURCE_1, 2, AMP_FMT,
		1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

	# currently this dai is here as "virtual" capture backend
	W_DAI_IN(SSP, SPK_SSP_INDEX, SPK_SSP_NAME, AMP_FMT, 3, 0)

	# Capture pipeline 9 from demux on PCM 6 using max 2 channels of s32le.
	PIPELINE_PCM_ADD(sof/pipe-passthrough-capture-sched.m4,
		9, 6, 2, s32le,
		1000, 1, 0,
		48000, 48000, 48000,
		SCHEDULE_TIME_DOMAIN_TIMER,
		PIPELINE_PLAYBACK_SCHED_COMP_1)

	# Connect demux to capture
	SectionGraph."PIPE_CAP" {
		index "0"

		lines [
			# mux to capture
			dapm(PIPELINE_SINK_9, PIPELINE_DEMUX_1)
		]
	}

	# Connect virtual capture to dai
	SectionGraph."PIPE_CAP_VIRT" {
		index "9"

		lines [
			# mux to capture
			dapm(ECHO REF 9, SPK_REF_DAI_NAME)
		]
	}',
	AMP_TYPE, `SMART', `
`	# playback DAI is SSP'AMP_SSP` using 2 periods'
`	# Buffers use 'AMP_FMT` format, with 48 frame per 1000us on core 0 with priority 0'
	DAI_ADD(sof/pipe-dai-playback.m4,
		2, SSP, SPK_SSP_INDEX, SPK_SSP_NAME,
		PIPELINE_SOURCE_2, 2, AMP_FMT,
		1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

`	# capture DAI is SSP'AMP_SSP` using 2 periods'
`	# Buffers use 'FMT` format, with 48 frame per 1000us on core 0 with priority 0'
	DAI_ADD(sof/pipe-dai-capture.m4,
		3, SSP, SPK_SSP_INDEX, SPK_SSP_NAME,
		PIPELINE_SINK_3, 2, AMP_FMT,
		1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)',
	)

# playback DAI is iDisp1 using 2 periods
# Buffers use s32le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-playback.m4,
	5, HDA, 0, iDisp1,
	PIPELINE_SOURCE_5, 2, s32le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# playback DAI is iDisp2 using 2 periods
# Buffers use s32le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-playback.m4,
	6, HDA, 1, iDisp2,
	PIPELINE_SOURCE_6, 2, s32le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# playback DAI is iDisp3 using 2 periods
# Buffers use s32le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-playback.m4,
	7, HDA, 2, iDisp3,
	PIPELINE_SOURCE_7, 2, s32le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# playback DAI is iDisp4 using 2 periods
# Buffers use s32le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-playback.m4,
	8, HDA, 3, iDisp4,
	PIPELINE_SOURCE_8, 2, s32le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# PCM Low Latency, id 0
dnl PCM_PLAYBACK_ADD(name, pcm_id, playback)

ifelse(
	AMP_TYPE, `DUMB', `
	PCM_PLAYBACK_ADD(Speakers, 0, PIPELINE_PCM_1)
	PCM_CAPTURE_ADD(EchoRef, 6, PIPELINE_PCM_9)',
	AMP_TYPE, `SMART', `
	PCM_DUPLEX_ADD(Speakers, 1, PIPELINE_PCM_2, PIPELINE_PCM_3)',
	)

PCM_PLAYBACK_ADD(HDMI1, 2, PIPELINE_PCM_5)
PCM_PLAYBACK_ADD(HDMI2, 3, PIPELINE_PCM_6)
PCM_PLAYBACK_ADD(HDMI3, 4, PIPELINE_PCM_7)
PCM_PLAYBACK_ADD(HDMI4, 5, PIPELINE_PCM_8)

#
# BE conf2igurations - overrides config in ACPI if present
#
dnl DAI_CONFIG(type, dai_index, link_id, name, ssp_config/dmic_config)
dnl SSP_CONFIG(format, mclk, bclk, fsync, tdm, ssp_config_data)
dnl SSP_CLOCK(clock, freq, codec_master, polarity)
dnl SSP_CONFIG_DATA(type, idx, valid bits, mclk_id)
dnl mclk_id is optional
dnl ssp1-maxmspk

# SSP SPK_SSP_INDEX (ID: SPK_BE_ID)
DAI_CONFIG(SSP, SPK_SSP_INDEX, SPK_BE_ID, SPK_SSP_NAME,
ifelse(
	AMP, `CS35L41', `
	SSP_CONFIG(DSP_A, SSP_CLOCK(mclk, 19200000, codec_mclk_in),
		SSP_CLOCK(bclk, 6144000, codec_slave),
		SSP_CLOCK(fsync, 48000, codec_slave),
		SSP_TDM(4, 32, 3, 15),
		SSP_CONFIG_DATA(SSP, SPK_SSP_INDEX, 24)))',
	)

# 4 HDMI/DP outputs (ID: 2,3,4,5)
DAI_CONFIG(HDA, 0, 2, iDisp1,
	HDA_CONFIG(HDA_CONFIG_DATA(HDA, 0, 48000, 2)))
DAI_CONFIG(HDA, 1, 3, iDisp2,
	HDA_CONFIG(HDA_CONFIG_DATA(HDA, 1, 48000, 2)))
DAI_CONFIG(HDA, 2, 4, iDisp3,
	HDA_CONFIG(HDA_CONFIG_DATA(HDA, 2, 48000, 2)))
DAI_CONFIG(HDA, 3, 5, iDisp4,
	HDA_CONFIG(HDA_CONFIG_DATA(HDA, 3, 48000, 2)))

DEBUG_END
