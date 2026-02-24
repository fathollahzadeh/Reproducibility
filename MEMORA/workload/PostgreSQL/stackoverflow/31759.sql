
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(NULLIF(p.Tags, ''), 'No Tags') AS CleanedTags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        RANK() OVER (ORDER BY SUM(v.BountyAmount) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        v.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Score,
    tu.DisplayName AS TopUser,
    tu.TotalBounty,
    rp.CleanedTags
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.PostId IN (
        SELECT 
            PL.RelatedPostId
        FROM 
            PostLinks PL
        WHERE 
            PL.PostId = rp.PostId
    )
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
