WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users)
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
ClosedPostCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseActionCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.VoteCount,
    ua.PostCount,
    pp.Title,
    pp.Score,
    COALESCE(cpc.CloseActionCount, 0) AS CloseCount
FROM 
    UserActivity ua
JOIN 
    PopularPosts pp ON ua.PostCount > 0 AND pp.Rank <= 10
LEFT JOIN 
    ClosedPostCounts cpc ON pp.PostId = cpc.PostId
WHERE 
    ua.VoteCount > 5
ORDER BY 
    ua.VoteCount DESC, pp.Score DESC;