
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        MAX(u.LastAccessDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        Upvotes,
        Downvotes,
        LastActiveDate,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, Reputation DESC) AS Rank
    FROM 
        UserStatistics
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.CommentCount,
    tu.Upvotes,
    tu.Downvotes,
    tu.LastActiveDate,
    pt.Name AS PostType
FROM 
    TopUsers tu
JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    tu.Rank <= 10 AND 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
ORDER BY 
    tu.Rank;
