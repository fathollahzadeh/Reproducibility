WITH RecursiveTags AS (
    SELECT
        t.Id,
        t.TagName,
        t.Count,
        ROW_NUMBER() OVER (ORDER BY t.Count DESC) AS Rank
    FROM Tags t
    WHERE t.Count > 0
),
UserReputation AS (
    SELECT
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users u
),
PostActivity AS (
    SELECT
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY p.OwnerUserId
),
UserStats AS (
    SELECT
        u.Id,
        u.DisplayName,
        COALESCE(pa.CommentsCount, 0) AS CommentsCount,
        COALESCE(pa.TotalBounties, 0) AS TotalBounties
    FROM Users u
    LEFT JOIN PostActivity pa ON u.Id = pa.OwnerUserId
)
SELECT
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationLevel,
    ut.CommentsCount,
    ut.TotalBounties,
    rt.TagName
FROM UserReputation ur
JOIN UserStats ut ON ur.Id = ut.Id
LEFT JOIN RecursiveTags rt ON rt.Rank <= 10
WHERE ur.Reputation > 500
ORDER BY ur.Reputation DESC, ut.TotalBounties DESC
LIMIT 50;