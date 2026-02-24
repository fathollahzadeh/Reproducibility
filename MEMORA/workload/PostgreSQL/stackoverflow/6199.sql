
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(p.Score, 0)) AS TotalPostScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        au.Id,
        au.DisplayName,
        au.TotalBadges,
        au.TotalPostScore,
        ROW_NUMBER() OVER (ORDER BY au.TotalPostScore DESC) AS Rank
    FROM 
        ActiveUsers au
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount,
    u.DisplayName AS OwnerDisplayName,
    tu.TotalBadges AS OwnerTotalBadges,
    tu.TotalPostScore AS OwnerPostScore
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    TopUsers tu ON u.Id = tu.Id
WHERE 
    rp.RowNum <= 5  
ORDER BY 
    tu.Rank, rp.CreationDate DESC;
