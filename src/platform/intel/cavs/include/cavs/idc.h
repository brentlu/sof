/* SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright(c) 2018 Intel Corporation. All rights reserved.
 *
 * Author: Tomasz Lauda <tomasz.lauda@linux.intel.com>
 */

#ifdef __PLATFORM_IDC_H__

#ifndef __CAVS_IDC_H__
#define __CAVS_IDC_H__

#include <arch/idc.h>

static inline int idc_send_msg(struct idc_msg *msg, uint32_t mode)
{
	return arch_idc_send_msg(msg, mode);
}

static inline int idc_init(void)
{
	return arch_idc_init();
}

#endif /* __CAVS_IDC_H__ */

#else

#error "This file shouldn't be included from outside of platform/idc.h"

#endif /* __PLATFORM_IDC_H__ */
