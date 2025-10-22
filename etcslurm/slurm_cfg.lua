return {
    -- Default values for omitted job characteristics
    defaults = {
        partition = "general", -- (see 1.0)
        time_limit = 240, -- 4 hours (see 2.0)
        cpus_per_task = 1, -- (see 2.0)
        min_mem_gpu = 24000, -- in MB (see 2.8)
    }
}
