
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.OwnerUserId, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '90 days'
), 
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
TopUsers AS (
    SELECT 
        us.UserId, 
        us.DisplayName, 
        us.Reputation, 
        us.TotalBounty, 
        us.PostCount, 
        us.QuestionCount, 
        us.AnswerCount,
        RANK() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM 
        UserStats us
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalBounty,
    tu.PostCount,
    p.Title AS RecentPostTitle,
    p.CreationDate AS RecentPostDate,
    p.ViewCount AS RecentPostViews,
    p.Score AS RecentPostScore
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPosts p ON tu.UserId = p.OwnerUserId 
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.Reputation DESC, p.ViewCount DESC
LIMIT 10;
