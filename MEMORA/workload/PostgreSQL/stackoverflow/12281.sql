
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),
AverageReputation AS (
    SELECT 
        AVG(Reputation) AS AvgReputation
    FROM 
        Users
),
HighPostCount AS (
    SELECT 
        UserId,
        PostCount
    FROM 
        UserStats
    WHERE 
        PostCount > (SELECT AVG(PostCount) FROM UserStats)
)
SELECT
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.BadgeCount,
    us.UpVoteCount,
    us.DownVoteCount,
    ar.AvgReputation,
    COALESCE(hpc.PostCount, 0) AS HighPostCountThreshold
FROM 
    UserStats us
CROSS JOIN 
    AverageReputation ar
LEFT JOIN 
    HighPostCount hpc ON us.UserId = hpc.UserId
ORDER BY 
    us.Reputation DESC, us.PostCount DESC;
