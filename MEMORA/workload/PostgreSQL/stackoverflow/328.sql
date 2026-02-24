WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserProfiles AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(u.Reputation, 0) as Reputation,
        COALESCE(b.BadgeCount, 0) as BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) as BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostMetrics AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        up.DisplayName,
        up.Reputation,
        up.BadgeCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        rp.Score,
        rp.TotalPosts
    FROM 
        RankedPosts rp
    JOIN 
        UserProfiles up ON rp.OwnerUserId = up.UserId
    LEFT JOIN 
        PostComments pc ON rp.Id = pc.PostId
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.DisplayName,
    pm.Reputation,
    pm.BadgeCount,
    pm.CommentCount,
    pm.Score,
    pm.TotalPosts,
    CASE 
        WHEN pm.Score >= 50 THEN 'High Score'
        WHEN pm.Score BETWEEN 20 AND 49 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN pm.Reputation >= 1000 THEN 'Influencer'
        ELSE 'Newbie'
    END AS UserCategory
FROM 
    PostMetrics pm
WHERE 
    pm.CommentCount > 5
ORDER BY 
    pm.Score DESC, 
    pm.CreationDate ASC;