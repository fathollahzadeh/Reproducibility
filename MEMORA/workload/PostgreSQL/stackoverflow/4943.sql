
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS TotalUpVotes,
        COALESCE(NULLIF(p.Body, ''), 'No content') AS BodyContent,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.PostId,
    up.Title,
    up.ViewCount,
    up.RankByViews,
    up.BodyContent,
    ub.BadgeCount,
    CASE 
        WHEN up.TotalUpVotes > 100 THEN 'Highly Upvoted'
        WHEN up.TotalUpVotes BETWEEN 50 AND 100 THEN 'Moderately Upvoted'
        ELSE 'Less Popular'
    END AS VoteStatus
FROM 
    RankedPosts up
LEFT JOIN 
    UserBadges ub ON up.OwnerUserId = ub.UserId
WHERE 
    up.RankByViews <= 5
ORDER BY 
    up.ViewCount DESC
LIMIT 10
OFFSET 0;
