WITH TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(vUp.VoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(vDown.VoteCount, 0)) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        WHERE VoteTypeId = 2 
        GROUP BY PostId
    ) vUp ON p.Id = vUp.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        WHERE VoteTypeId = 3 
        GROUP BY PostId
    ) vDown ON p.Id = vDown.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopPostTypes AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM PostTypes pt
    LEFT JOIN Posts p ON pt.Id = p.PostTypeId
    GROUP BY pt.Name
),
ClosedPosts AS (
    SELECT 
        COUNT(*) AS ClosedPostCount,
        SUM(v.Score) AS TotalClosedScore
    FROM Posts v
    WHERE v.ClosedDate IS NOT NULL
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tpt.PostTypeName,
    tpt.PostCount AS PostTypeCount,
    tpt.TotalScore,
    cp.ClosedPostCount,
    cp.TotalClosedScore
FROM TopUsers tu
CROSS JOIN TopPostTypes tpt
CROSS JOIN ClosedPosts cp
ORDER BY tu.Reputation DESC, tpt.PostCount DESC;