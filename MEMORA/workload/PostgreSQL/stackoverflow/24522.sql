WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ua.TotalUpvotes,
        ua.TotalDownvotes,
        ua.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserActivity ua ON rp.OwnerUserId = ua.UserId
    WHERE 
        rp.Rank <= 5
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.ViewCount,
    COALESCE(pm.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(pm.TotalDownvotes, 0) AS TotalDownvotes,
    COALESCE(pm.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN pm.Score IS NULL THEN 'No Score'
        WHEN pm.Score >= 100 THEN 'Highly Rated'
        ELSE 'Moderately Rated'
    END AS RatingClassification,
    SUBSTRING(pm.Title, 1, 50) || '...' AS ShortenedTitle,
    CASE 
        WHEN pm.ViewCount IS NULL THEN 'Unknown Views'
        WHEN pm.ViewCount < 100 THEN 'Low Traffic'
        ELSE 'High Traffic'
    END AS TrafficStatus
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC
;