
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS ActivityRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
ClosingReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS ClosingReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::integer = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.QuestionsCount,
    ua.AnswersCount,
    ua.TotalBounty,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore,
    pp.ViewCount AS PopularPostViews,
    cr.ClosingReasons
FROM UserActivity ua
LEFT JOIN PopularPosts pp ON ua.UserId = pp.Id
LEFT JOIN ClosingReasons cr ON pp.Id = cr.PostId
WHERE ua.ActivityRank <= 10
ORDER BY ua.Reputation DESC, pp.Score DESC NULLS LAST;
