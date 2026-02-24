WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserPostCounts AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS RecentPostCount
    FROM 
        RecentPosts rp
    GROUP BY 
        rp.OwnerUserId
),
TopUsers AS (
    SELECT 
        ru.UserId,
        ru.DisplayName,
        ru.Reputation,
        upc.RecentPostCount
    FROM 
        RankedUsers ru
    JOIN 
        UserPostCounts upc ON ru.UserId = upc.OwnerUserId
    WHERE 
        ru.ReputationRank <= 100
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.RecentPostCount,
    COALESCE(SUM(p.Score), 0) AS TotalPostScore,
    COALESCE(SUM(c.Score), 0) AS TotalCommentScore
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON p.OwnerUserId = tu.UserId
LEFT JOIN 
    Comments c ON c.UserId = tu.UserId
GROUP BY 
    tu.DisplayName, tu.Reputation, tu.RecentPostCount
ORDER BY 
    tu.Reputation DESC;