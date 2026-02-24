
WITH PostStatistics AS (
    SELECT
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM
        Posts p
    GROUP BY
        p.PostTypeId
),
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(u.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(u.DownVotes), 0) AS TotalDownVotes,
        AVG(COALESCE(u.Reputation, 0)) AS AvgReputation
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
)
SELECT
    p.PostTypeId,
    p.TotalPosts,
    p.TotalViews,
    p.TotalScore,
    p.AvgViews,
    p.AvgScore,
    u.PostCount AS UserPostCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.AvgReputation
FROM
    PostStatistics p
LEFT JOIN
    UserStatistics u ON p.PostTypeId = (
        SELECT
            PostTypeId
        FROM
            Posts
        ORDER BY
            RANDOM()
        LIMIT 1
    )
ORDER BY
    p.PostTypeId;
