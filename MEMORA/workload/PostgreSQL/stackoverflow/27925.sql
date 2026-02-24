WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalPostViews,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
FavoritePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COUNT(v.Id) AS FavoriteCount
    FROM Posts p
    LEFT JOIN Votes v ON v.PostId = p.Id AND v.VoteTypeId = 5 
    WHERE p.FavoriteCount > 0
    GROUP BY p.Id, p.Title, p.ViewCount, p.AnswerCount
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalAnswers,
    ts.TotalComments,
    us.DisplayName AS UserWithMostPosts,
    us.TotalPosts,
    us.TotalPostViews,
    us.TotalBadges,
    fp.Title AS FavoritePostTitle,
    fp.ViewCount AS FavoritePostViews,
    fp.AnswerCount AS FavoritePostAnswers,
    fp.FavoriteCount AS FavoritePostFavorites
FROM TagStats ts
JOIN UserStats us ON us.TotalPosts = (SELECT MAX(TotalPosts) FROM UserStats)
JOIN FavoritePosts fp ON fp.FavoriteCount = (SELECT MAX(FavoriteCount) FROM FavoritePosts)
ORDER BY ts.TotalViews DESC, ts.PostCount DESC
LIMIT 10;