WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
PostMetrics AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        CASE 
            WHEN rp.Score >= 10 THEN 'Highly Scored'
            WHEN rp.Score BETWEEN 5 AND 9 THEN 'Moderately Scored'
            ELSE 'Low Scored' 
        END AS ScoreCategory,
        au.DisplayName AS UserName,
        au.Reputation,
        rp.CommentCount,
        rp.ViewCount
    FROM 
        RankedPosts rp
    JOIN 
        ActiveUsers au ON rp.OwnerUserId = au.Id
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.ScoreCategory,
    pm.UserName,
    pm.Reputation,
    pm.CommentCount,
    pm.ViewCount,
    COALESCE(h.UserId, 0) AS LastUserId,
    COALESCE(h.CreationDate, cast('2024-10-01 12:34:56' as timestamp)) AS LastActivityDate,
    h.Comment AS LastAction 
FROM 
    PostMetrics pm
LEFT JOIN 
    PostHistory h ON pm.PostId = h.PostId 
    AND h.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = pm.PostId)
ORDER BY 
    pm.Reputation DESC,
    pm.ViewCount DESC;