
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        AVG(p.ViewCount) AS AvgViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalVotes,
        TotalBadges,
        AvgViews,
        RANK() OVER (ORDER BY TotalScore DESC, TotalPosts DESC) AS UserRank
    FROM UserStatistics
)
SELECT
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalScore,
    u.TotalVotes,
    u.TotalBadges,
    u.AvgViews,
    RANK() OVER (ORDER BY u.TotalScore DESC) AS RankByScore,
    RANK() OVER (ORDER BY u.TotalPosts DESC) AS RankByPosts
FROM TopUsers u
WHERE u.UserRank <= 10
ORDER BY u.TotalScore DESC, u.TotalPosts DESC;
