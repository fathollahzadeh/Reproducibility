WITH TotalPosts AS (
    SELECT COUNT(*) AS TotalPostCount
    FROM Posts
),
PostsByType AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY pt.Name
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostsCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
    ORDER BY PostsCount DESC
    LIMIT 10
),
VotesStatistics AS (
    SELECT 
        vt.Name AS VoteTypeName,
        COUNT(v.Id) AS VoteCount
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY vt.Name
)

SELECT 
    (SELECT TotalPostCount FROM TotalPosts) AS TotalPosts,
    pp.PostTypeName,
    pp.PostCount,
    tu.DisplayName,
    tu.Reputation,
    tu.PostsCount,
    vs.VoteTypeName,
    vs.VoteCount
FROM PostsByType pp
CROSS JOIN TopUsers tu
CROSS JOIN VotesStatistics vs;