WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentComments AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.Text,
        c.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rpt.Title,
    rpt.Score,
    rpt.ViewCount,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount
FROM 
    UserStats up
JOIN 
    RankedPosts rpt ON up.UserId = rpt.OwnerUserId AND rpt.Rank = 1
LEFT JOIN (
    SELECT 
        rc.PostId,
        COUNT(rc.CommentId) AS CommentCount
    FROM 
        RecentComments rc
    GROUP BY 
        rc.PostId
) rc ON rpt.PostId = rc.PostId
WHERE 
    up.Reputation > 1000
ORDER BY 
    up.Reputation DESC, rpt.Score DESC
LIMIT 10
OFFSET 0;