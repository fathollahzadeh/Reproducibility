WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY p.Id
),
PostTagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(p.Score) AS TotalPostScore,
        SUM(p.ViewCount) AS TotalPostViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
)
SELECT 
    ru.DisplayName AS TopUser,
    ru.Reputation AS UserReputation,
    ap.PostId,
    ap.Title AS PostTitle,
    ap.ViewCount AS PostViews,
    ap.Score AS PostScore,
    COUNT(c.Id) AS CommentsOnPost,
    COALESCE(tgs.PostCount, 0) AS PostsWithSameTagCount,
    tgs.TotalViews AS TotalViewsForTag,
    tgs.TotalScore AS TotalScoreForTag
FROM RankedUsers ru
JOIN ActivePosts ap ON ru.UserId = ap.OwnerUserId
LEFT JOIN Comments c ON ap.PostId = c.PostId
LEFT JOIN PostTagStats tgs ON ap.Tags LIKE '%' || tgs.TagName || '%'
WHERE ru.ReputationRank <= 10
GROUP BY ru.DisplayName, ru.Reputation, ap.PostId, ap.Title, ap.ViewCount, ap.Score, tgs.PostCount, tgs.TotalViews, tgs.TotalScore
ORDER BY ru.Reputation DESC, ap.Score DESC
LIMIT 50;