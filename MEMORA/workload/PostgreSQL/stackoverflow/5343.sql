WITH UserVotes AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount END) AS AvgViews,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score END) AS AvgScore
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        AvgViews,
        AvgScore,
        RANK() OVER (ORDER BY UpVotes DESC, PostCount DESC) AS Rank
    FROM UserVotes
)
SELECT
    t.DisplayName,
    t.UpVotes,
    t.DownVotes,
    t.PostCount,
    t.AvgViews,
    t.AvgScore,
    CASE 
        WHEN t.Rank <= 10 THEN 'Top 10'
        WHEN t.Rank <= 50 THEN 'Top 50'
        ELSE 'Others'
    END AS UserCategory
FROM TopUsers t
WHERE t.Rank <= 100
ORDER BY t.Rank;
