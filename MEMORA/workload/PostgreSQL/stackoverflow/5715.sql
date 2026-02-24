WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        ClosedPostCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserActivity
),
UserBadges AS (
    SELECT 
        UB.UserId,
        COUNT(UB.Id) AS BadgeCount
    FROM 
        Badges UB
    GROUP BY 
        UB.UserId
),
UserMetrics AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TU.Reputation,
        TU.PostCount,
        TU.AnswerCount,
        TU.ClosedPostCount,
        UB.BadgeCount,
        (TU.Reputation + COALESCE(UB.BadgeCount, 0) * 10) AS MetricScore
    FROM 
        TopUsers TU
    LEFT JOIN 
        UserBadges UB ON TU.UserId = UB.UserId
)
SELECT 
    UM.UserId,
    UM.DisplayName,
    UM.Reputation,
    UM.PostCount,
    UM.AnswerCount,
    UM.ClosedPostCount,
    UM.BadgeCount,
    UM.MetricScore
FROM 
    UserMetrics UM
WHERE 
    UM.MetricScore > 100
ORDER BY 
    UM.MetricScore DESC
LIMIT 10;
