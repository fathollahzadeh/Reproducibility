WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostAggregates AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts
    GROUP BY OwnerUserId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS ClosedDate,
        u.DisplayName AS ClosedBy
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN Users u ON ph.UserId = u.Id
),
UserBadges AS (
    SELECT 
        UserId,
        STRING_AGG(Name, ', ') AS Badges
    FROM Badges
    GROUP BY UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ua.TotalPosts,
    ua.QuestionCount,
    ua.AnswerCount,
    ub.Badges,
    COALESCE(cp.ClosedDate, NULL) AS LastClosedPostDate,
    CASE 
        WHEN ur.ReputationRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserTier
FROM Users u
LEFT JOIN PostAggregates ua ON u.Id = ua.OwnerUserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN (
    SELECT 
        cp.ClosedBy, 
        MAX(cp.ClosedDate) AS ClosedDate 
    FROM ClosedPosts cp
    GROUP BY cp.ClosedBy
) cp ON u.DisplayName = cp.ClosedBy
JOIN UserReputation ur ON u.Id = ur.UserId
WHERE u.Reputation > 100
ORDER BY u.Reputation DESC, u.DisplayName ASC;
