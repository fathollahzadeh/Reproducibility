WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  
),
PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rc.CommentCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) rc ON rp.PostId = rc.PostId
    WHERE 
        rp.Rank <= 5  
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.CreationDate,
    pwc.ViewCount,
    pwc.Score,
    pwc.CommentCount,
    pwc.OwnerDisplayName,
    CASE 
        WHEN pwc.Score > 10 THEN 'High Engagement'
        WHEN pwc.Score BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementCategory,
    EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = pwc.PostId 
        AND v.VoteTypeId = 2  
    ) AS HasUpvotes
FROM 
    PostWithComments pwc
ORDER BY 
    pwc.ViewCount DESC, 
    pwc.CreationDate ASC;