--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'CPed'
shared.require 'CTask'
shared.require 'CTaskTimer'

shared.ffi.cdef[[
	typedef struct CEventHandlerHistory
	{
		CTask *m_pAbortedTask;
		void *m_pCurrentEventActive;
		void *m_pCurrentEventPassive;
		void *m_pStoredEventActive;
		CTaskTimer m_storeTimer;
	} CEventHandlerHistory;

	// Fully not reversed. I think it is appropriate to fully replace it with original structure.
	typedef struct CEventHandler
	{
		CPed *pPed;
		CEventHandlerHistory m_history;
		CTask *m_pTaskPhysResponse;
		CTask *m_pTaskEventResponse;
		CTask *m_pTaskSecondaryAim; // Simple task
		CTask *m_pTaskSecondarySay; // Simple task
		CTask *m_pTaskSecondaryPartialAnim; // Simple task
	} CEventHandler;
]]

--shared.validate_size('CEventHandler', 0x34)
