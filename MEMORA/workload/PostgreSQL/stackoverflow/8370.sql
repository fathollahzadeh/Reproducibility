
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT *
    FROM RankedUsers
    WHERE UserRank <= 10
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY pt.Name
)
SELECT 
    t.DisplayName,
    t.PostCount AS UserPostCount,
    t.TotalScore AS UserTotalScore,
    t.TotalUpVotes,
    t.TotalDownVotes,
    ps.PostType,
    ps.PostCount AS TypePostCount,
    ps.TotalViews,
    ps.AverageScore
FROM TopUsers t
CROSS JOIN PostStatistics ps
ORDER BY t.TotalScore DESC, ps.TotalViews DESC;
