
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS post_rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalBounties,
        us.TotalPosts,
        us.TotalBadges,
        RANK() OVER (ORDER BY us.TotalPosts DESC, us.TotalBounties DESC) AS user_rank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 0
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalBounties,
    tu.TotalBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.post_rank = 1
WHERE 
    tu.user_rank <= 10
ORDER BY 
    tu.user_rank, tu.TotalBounties DESC;
