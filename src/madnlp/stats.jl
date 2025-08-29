function obj(stats::MadNLPExecutionStats{T, VT})::T where {T,VT}
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

function get_n(stats::MadNLPExecutionStats)
    return length(stats.solution)
end

function get_m(stats::MadNLPExecutionStats)
    return length(stats.constraints)
end

function success(stats::MadNLPExecutionStats{T, VT}) where {T,VT}
    return MadNLP.SOLVE_SUCCEEDED <= stats.status <= MadNLP.SOLVED_TO_ACCEPTABLE_LEVEL
    # TODO SEARCH_DIRECTION_BECOMES_TOO_SMALL is not technically a success but might be
end
