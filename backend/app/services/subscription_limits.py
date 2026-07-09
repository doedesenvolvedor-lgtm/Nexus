PLAN_LIMITS = {
    'free': 1,
    'basic': 1,
    'standard': 2,
    'premium': 4,
}


def can_watch(plan: str, active_sessions: int) -> bool:
    limit = PLAN_LIMITS.get(plan.lower(), 1)
    return active_sessions < limit
