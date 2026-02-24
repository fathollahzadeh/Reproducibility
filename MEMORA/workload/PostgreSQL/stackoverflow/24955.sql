
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 years'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AvgBounty,
        CASE 
            WHEN rp.RN = 1 THEN 'Top Post'
            WHEN rp.RN > 1 AND rp.CommentCount > 0 THEN 'Regular Post with Comments'
            ELSE 'Moderated Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 0 OR rp.Score > 10
),
FinalOutput AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.ViewCount,
        fp.OwnerDisplayName,
        fp.PostCategory,
        COALESCE(NULLIF(fp.AvgBounty, 0), -1) AS EffectiveAvgBounty 
    FROM 
        FilteredPosts fp
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.OwnerDisplayName,
    f.PostCategory,
    CASE 
        WHEN f.EffectiveAvgBounty = -1 THEN 'No Bounty'
        WHEN f.EffectiveAvgBounty > 100 THEN 'High Bounty'
        ELSE 'Normal Bounty'
    END AS BountyCategory
FROM 
    FinalOutput f
ORDER BY 
    f.CreationDate DESC, f.Score DESC
LIMIT 100;
