WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentTotal
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
)
SELECT 
    tu.DisplayName,
    tu.TotalViews,
    rp.Title,
    rp.ViewCount,
    rp.CommentTotal,
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostCategory
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.TotalViews DESC, rp.ViewCount DESC
LIMIT 100;