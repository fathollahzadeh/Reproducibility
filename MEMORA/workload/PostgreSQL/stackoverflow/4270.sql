WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.ViewCount > 1000
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankByScore,
    COALESCE(ut.UserCount, 0) AS UniqueUserVotes,
    CASE 
        WHEN rp.TotalBounty IS NULL THEN 'No Bounty'
        ELSE CONCAT('Total Bounty: $', rp.TotalBounty)
    END AS BountyInfo
FROM 
    RankedPosts rp
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(DISTINCT UserId) AS UserCount
    FROM 
        Votes
    WHERE 
        VoteTypeId IN (2, 3) 
    GROUP BY 
        PostId
) ut ON rp.PostId = ut.PostId
WHERE 
    rp.RankByScore <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount ASC
LIMIT 50;