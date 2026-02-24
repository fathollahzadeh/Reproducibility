WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
MetaBadge AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ClosedPostCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.UserId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.Reputation,
    COALESCE(m.Badges, 'No Badges') AS UserBadges,
    COALESCE(c.ClosedCount, 0) AS ClosedQuestions,
    CASE 
        WHEN p.Score IS NULL THEN 'No Score'
        WHEN p.Score > 100 THEN 'High Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    (CASE 
        WHEN p.Rank = 1 THEN 'Latest Question by User'
        ELSE 'Older Question'
    END) AS UserPostType,
    (SELECT 
        COUNT(DISTINCT pl.RelatedPostId) 
     FROM 
        PostLinks pl 
     WHERE 
        pl.PostId = p.PostId AND pl.LinkTypeId = 3 
    ) AS DuplicateLinks
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    MetaBadge m ON u.Id = m.UserId
LEFT JOIN 
    ClosedPostCounts c ON u.Id = c.UserId
WHERE 
    p.Rank = 1
ORDER BY 
    p.CreationDate DESC
LIMIT 10;