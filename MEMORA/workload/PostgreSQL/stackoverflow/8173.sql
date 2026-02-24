WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        rp.rn <= 5  
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount
),
FinalOutput AS (
    SELECT 
        pm.*,
        CASE 
            WHEN pm.Score > 100 THEN 'Hot' 
            WHEN pm.Score > 50 THEN 'Popular' 
            ELSE 'Normal' 
        END AS Popularity
    FROM 
        PostMetrics pm
)
SELECT 
    fo.PostId,
    fo.Title,
    fo.OwnerDisplayName,
    fo.CreationDate,
    fo.Score,
    fo.ViewCount,
    fo.CommentCount,
    fo.TotalBounty,
    fo.Popularity
FROM 
    FinalOutput fo
ORDER BY 
    fo.Popularity DESC, fo.Score DESC
LIMIT 50;