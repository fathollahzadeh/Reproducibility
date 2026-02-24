WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount,
        SUM(COALESCE(v.UserId, 0)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        BadgeCount, 
        TotalBountyAmount, 
        TotalVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM 
        UserStats
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    BadgeCount,
    TotalBountyAmount,
    TotalVotes,
    ReputationRank,
    PostCountRank
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10 OR PostCountRank <= 10
ORDER BY 
    ReputationRank, PostCountRank;