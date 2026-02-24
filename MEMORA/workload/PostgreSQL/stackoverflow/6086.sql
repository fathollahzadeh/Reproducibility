
WITH UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswersCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        AVG(p.CommentCount) AS AverageCommentCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        COALESCE(c.UserDisplayName, 'No Comments') AS LastCommentBy,
        c.CreationDate AS LastCommentDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
UserPostEngagement AS (
    SELECT
        us.DisplayName AS UserDisplayName,
        COUNT(pd.PostId) AS PostsCreated,
        SUM(pd.ViewCount) AS TotalViews,
        SUM(pd.Score) AS TotalPostScore,
        MAX(pd.PostCreationDate) AS MostRecentPost
    FROM UserStatistics us
    JOIN PostDetails pd ON us.UserId = pd.PostId
    GROUP BY us.DisplayName
)
SELECT
    us.DisplayName,
    us.TotalPosts,
    us.QuestionsCount,
    us.AnswersCount,
    us.AcceptedAnswersCount,
    us.TotalScore,
    us.AverageViewCount,
    us.AverageCommentCount,
    COALESCE(up.PostsCreated, 0) AS PostsCreated,
    COALESCE(up.TotalViews, 0) AS TotalViews,
    COALESCE(up.TotalPostScore, 0) AS TotalPostScore,
    up.MostRecentPost
FROM UserStatistics us
LEFT JOIN UserPostEngagement up ON us.DisplayName = up.UserDisplayName
ORDER BY us.TotalScore DESC, us.TotalPosts DESC;
