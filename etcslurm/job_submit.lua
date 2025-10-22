-- job_submit.lua
local slurm_cfg = dofile("/etc/slurm/slurm_cfg.lua")
local defaults = slurm_cfg.defaults or {}

local function get_timestamp(datestring)
    -- "2025-10-21T14:00:00"
    local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)"
    local xyear, xmonth, xday, xhour, xminute, xseconds = datestring:match(pattern) 
    local timestamp = os.time({year = xyear, month = xmonth, day = xday, hour = xhour, min = xminute, sec = xseconds})  
    -- seconds since the epoch
    return timestamp
end

local function time_until(datestring)
    local timestamp = get_timestamp(datestring)
    local now = os.time()
    local time_diff = timestamp - now
    local minutes_diff = math.floor(time_diff / 60)
    return minutes_diff
end

local function is_maintenance()
    local maint_file = "/etc/slurm/maintenance.lua"
    local f = io.open(maint_file, "r")
    if f then
        io.close(f)
        maint = dofile(maint_file)
        maint_times = maint.maintenance or {}
        if time_until(maint_times.endtime) > 0 then
            return true, time_until(maint_times.starttime)
        end
    end
    return false, nil
end

local function time_format(minutes)
    local days = math.floor(minutes / 1440)
    local hours = math.floor(minutes / 60) - days*24
    local remainingminutes = minutes % 60
    -- Format the output to ensure two digits for minutes and seconds
    return string.format("%02d-%02d:%02d", days, hours, remainingminutes)
end
    

local function log_job_desc(jd)
    local JOB_DESC_FIELDS = {
        "account","acctg_freq","argv","begin_time","burst_buffer",
        "command","comment","constraints","contiguous","core_spec",
        "cpus_per_task","dependency","env_vars","features","gres",
        "group_id","immediate","job_id","licenses","mail_type",
        "mail_user","mem_per_cpu","min_nodes","max_nodes","name",
        "nodes","ntasks","partition","priority","qos","requeue",
        "reservation","script","shared","time_limit","user_id","work_dir"
    }
    -- time_limit is in minutes
    for _, k in ipairs(JOB_DESC_FIELDS) do
        local v = jd[k]
        if v ~= nil then
            slurm.log_user("%s = %s", k, tostring(v))
        else
            slurm.log_user("%s = <nil>", k)
        end
    end
end

function slurm_job_submit(job_desc, part_list, submit_uid)
    --slurm.log_user("Hello worlds")
    if job_desc.partition == nil then
        job_desc.partition = defaults.partition
        slurm.log_user("No partition set, partition set to %s", defaults.partition)
    end

    local maint_now, min_until = is_maintenance()
    if maint_now then
        slurm.log_user("maintenance!")
        slurm.log_user("maintenance: %s", min_until)
    else
        slurm.log_user("not maintenance")
    end
    if job_desc.time_limit > min_until then
        slurm.log_user("Your job can't run because it overlaps with the maintenance period.")
        slurm.log_user("If your job can run in %s minutes, please consider updating your job so it can run now:", min_until-10)
        slurm.log_user("\tscontrol update job JOBID timelimit=%s", time_format(min_until-10))
        slurm.log_user("(Replace JOBID with your jobid.)")
    end
    --log_job_desc(job_desc)
    return slurm.SUCCESS
end

function slurm_job_modify(job_desc, job_rec, part_list, modify_uid)
    return slurm.SUCCESS
end
