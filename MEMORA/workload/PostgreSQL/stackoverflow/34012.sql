WITH RECURSIVE UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        uc.PostCount,
        ROW_NUMBER() OVER (ORDER BY uc.PostCount DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        UserPostCounts uc ON u.Id = uc.UserId
    WHERE 
        uc.PostCount > 5
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.Score AS RecentPostScore,
    COALESCE(ARRAY_AGG(c.Text ORDER BY c.CreationDate DESC), '{}') AS RecentPostComments,
    pt.Name AS PostType
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPosts rp ON tu.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    Posts p ON p.Id = rp.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON c.PostId = rp.PostId
WHERE 
    tu.UserRank <= 10
GROUP BY 
    tu.DisplayName, tu.PostCount, rp.Title, rp.CreationDate, rp.Score, pt.Name
ORDER BY 
    tu.PostCount DESC;