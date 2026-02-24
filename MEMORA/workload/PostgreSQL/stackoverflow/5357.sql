
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 /* Questions only */
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
),
MostDiscussedPosts AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.CreationDate,
        pp.ViewCount,
        pp.CommentCount,
        ROW_NUMBER() OVER (ORDER BY pp.CommentCount DESC) AS DiscussionRank
    FROM PopularPosts pp
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    pp.Title AS MostDiscussedPostTitle,
    pp.Score AS PostScore,
    pp.ViewCount AS PostViewCount,
    pp.CommentCount AS TotalComments,
    pp.CreationDate AS PostCreationDate,
    pp.DiscussionRank
FROM RankedUsers ru
JOIN MostDiscussedPosts pp ON ru.UserId = pp.PostId
WHERE ru.UserRank <= 10 /* Top 10 users by reputation */
ORDER BY pp.DiscussionRank
