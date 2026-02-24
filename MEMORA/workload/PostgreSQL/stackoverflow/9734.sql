WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),

RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
)

SELECT 
    rp.*,
    rp.Score + rp.CommentCount * 2 + rp.VoteCount * 5 AS PostEngagementScore,
    CASE 
        WHEN rp.RankScore <= 10 THEN 'Top Posts'
        WHEN rp.RankScore <= 30 THEN 'Trending Posts'
        ELSE 'New Posts'
    END AS PostCategory,
    r.RecentEngagementScore
FROM 
    RankedPosts rp
LEFT JOIN (
    SELECT 
        Id,
        Score + CommentCount * 2 + VoteCount * 5 AS RecentEngagementScore
    FROM 
        RecentPosts
) r ON rp.Id = r.Id
WHERE 
    rp.Score > 0
ORDER BY 
    PostEngagementScore DESC, rp.CreationDate DESC
LIMIT 50;