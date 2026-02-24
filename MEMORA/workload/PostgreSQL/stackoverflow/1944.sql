WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND 
        p.Score IS NOT NULL
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(c.Score) AS AverageCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.RowNum,
        ue.CommentCount,
        ue.AverageCommentScore,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    JOIN 
        UserEngagement ue ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ue.UserId)
    WHERE 
        rp.RowNum <= 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.CommentCount,
    COALESCE(pp.TotalBounty, 0) AS TotalBounty,
    CASE 
        WHEN pp.AverageCommentScore > 5 THEN 'High Engagement'
        WHEN pp.AverageCommentScore BETWEEN 3 AND 5 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PopularPosts pp
ORDER BY 
    pp.Score DESC, 
    pp.CommentCount DESC
LIMIT 10;