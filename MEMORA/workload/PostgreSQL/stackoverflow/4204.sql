WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Score, p.ViewCount
), PostDetails AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.ViewCount, 
        rp.Rank,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        rp.CommentCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.PostId = b.UserId AND b.Class = 1  
), FilteredPosts AS (
    SELECT 
        pd.*,
        CASE WHEN pd.ViewCount = 0 THEN 'No Views' ELSE 'Views Available' END AS ViewStatus
    FROM 
        PostDetails pd
    WHERE 
        pd.Rank <= 5
)
SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.ViewCount,
    f.BadgeName,
    f.CommentCount,
    f.TotalBounty,
    f.ViewStatus
FROM 
    FilteredPosts f
ORDER BY 
    f.TotalBounty DESC, f.Score DESC;