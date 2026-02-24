WITH PostStats AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AverageViewCount,
        AVG(Score) AS AverageScore,
        SUM(CASE WHEN PostTypeId = 1 THEN AnswerCount ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN CommentCount IS NOT NULL THEN CommentCount ELSE 0 END) AS TotalComments
    FROM Posts
    GROUP BY PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        AVG(p.ViewCount) AS AvgPostViews
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
)
SELECT 
    p.PostTypeId,
    p.TotalPosts,
    p.AverageViewCount,
    p.AverageScore,
    p.TotalAnswers,
    p.TotalComments,
    u.UserId,
    u.Reputation,
    u.BadgeCount,
    u.AvgPostViews
FROM PostStats p
JOIN UserReputation u ON u.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE PostTypeId = p.PostTypeId)
ORDER BY p.PostTypeId, u.Reputation DESC;