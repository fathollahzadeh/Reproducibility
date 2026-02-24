
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
PopularPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.OwnerDisplayName, 
        rp.Score, 
        rp.ViewCount, 
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalBounties DESC
    LIMIT 10
)
SELECT 
    pp.Title AS PopularPostTitle,
    pp.OwnerDisplayName AS PostOwner,
    pp.Score AS PostScore,
    pp.ViewCount AS PostViews,
    pu.DisplayName AS TopUser,
    pu.TotalBounties
FROM 
    PopularPosts pp
CROSS JOIN 
    TopUsers pu
ORDER BY 
    pp.Score DESC, pu.TotalBounties DESC
LIMIT 10;
