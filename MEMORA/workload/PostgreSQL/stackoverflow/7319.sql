
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount, 
        COUNT(DISTINCT c.Id) AS CommentCount, 
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        Reputation, 
        PostCount, 
        CommentCount, 
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
)
SELECT 
    u.DisplayName,
    u.Reputation,
    pu.PostCount,
    pu.CommentCount,
    pu.BadgeCount,
    pt.Name AS PostTypeName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN pt.Id = 1 THEN 1 ELSE 0 END) AS Questions,
    SUM(CASE WHEN pt.Id = 2 THEN 1 ELSE 0 END) AS Answers,
    SUM(CASE WHEN pt.Id = 3 THEN 1 ELSE 0 END) AS Wikis
FROM 
    Users u
JOIN 
    TopUsers pu ON u.Id = pu.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    pu.ReputationRank <= 10
GROUP BY 
    u.DisplayName, u.Reputation, pu.PostCount, pu.CommentCount, pu.BadgeCount, pt.Name, pu.ReputationRank
ORDER BY 
    pu.ReputationRank;
