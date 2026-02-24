WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounties
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankByScore,
        rp.CommentCount,
        rp.TotalBounties
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5 OR rp.CommentCount > 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    COALESCE(fp.CommentCount, 0) AS CommentCount,
    COALESCE(fp.TotalBounties, 0) AS TotalBounties,
    CASE 
        WHEN fp.TotalBounties > 0 THEN 'Has Bounties'
        ELSE 'No Bounties'
    END AS BountyStatus
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC;