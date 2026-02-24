WITH UserStats AS (
    SELECT 
        Id AS UserId,
        Reputation,
        UpVotes,
        DownVotes,
        Views,
        CreationDate
    FROM Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
),
AggregatePostStats AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments
    FROM PostStats
    GROUP BY PostTypeId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPostsByUser,
        SUM(p.ViewCount) AS TotalViewsByUser,
        AVG(p.Score) AS AverageScoreByUser
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
)

SELECT 
    u.UserId,
    u.Reputation,
    ups.TotalPostsByUser,
    ups.TotalViewsByUser,
    ups.AverageScoreByUser,
    aps.PostTypeId,
    aps.TotalPosts AS TotalPostsByType,
    aps.TotalViews AS TotalViewsByType,
    aps.AverageScore AS AverageScoreByType,
    aps.TotalAnswers,
    aps.TotalComments
FROM UserStats u
JOIN UserPostStats ups ON u.UserId = ups.UserId
JOIN AggregatePostStats aps ON aps.TotalPosts > 0
ORDER BY u.Reputation DESC, aps.TotalViews DESC;