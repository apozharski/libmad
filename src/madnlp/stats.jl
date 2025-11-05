function obj(stats::MadNLPExecutionStats{T})::T where {T}
    return stats.objective
end

function solution(stats::MadNLPExecutionStats{T, VT})::VT where {T,VT}
    return stats.solution
end

function constraints(stats::MadNLPExecutionStats{T, VT})::VT where {T,VT}
    return stats.constraints
end

function multipliers(stats::MadNLPExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers
end

function multipliers_L(stats::MadNLPExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers_L
end

function multipliers_U(stats::MadNLPExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers_U
end

function get_n(stats::MadNLPExecutionStats)::Int
    return length(stats.solution)
end

function get_m(stats::MadNLPExecutionStats)::Int
    return length(stats.constraints)
end

function success(stats::MadNLPExecutionStats{T, VT}) where {T,VT}
    return MadNLP.SOLVE_SUCCEEDED <= stats.status <= MadNLP.SOLVED_TO_ACCEPTABLE_LEVEL
    # TODO SEARCH_DIRECTION_BECOMES_TOO_SMALL is not technically a success but might be
end

function iters(stats::MadNLPExecutionStats)
    return stats.iter
end

function primal_feas(stats::MadNLPExecutionStats{T}) where T
    return stats.primal_feas
end

function dual_feas(stats::MadNLPExecutionStats{T}) where T
    return stats.dual_feas
end

function status(stats::MadNLPExecutionStats)
    return Int(stats.status)
end
