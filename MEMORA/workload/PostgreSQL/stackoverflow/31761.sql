
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalComments,
        ua.TotalBounties,
        RANK() OVER (ORDER BY ua.TotalPosts DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalPosts > 5
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    CASE 
        WHEN tp.PostRank = 1 THEN 'Newest Post'
        ELSE 'Older Post'
    END AS PostStatus,
    COUNT(tb.TagName) AS TagCount,
    COALESCE(b.Name, 'No Badge') AS TopBadge
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
JOIN 
    RankedPosts tp ON u.Id = tp.OwnerUserId
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Tags tb ON p.Tags LIKE '%' || tb.TagName || '%'
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1  
WHERE 
    tb.IsRequired IS NULL  
GROUP BY 
    u.Id, u.DisplayName, tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.PostRank, b.Name, tu.UserRank
ORDER BY 
    tu.UserRank, tp.Score DESC;
