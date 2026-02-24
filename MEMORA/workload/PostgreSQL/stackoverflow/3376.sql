
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews, 
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        RANK() OVER (ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS ViewRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, TotalPosts, TotalViews, AcceptedAnswers
    FROM UserActivity
    WHERE ViewRank <= 10
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(ph.CreationDate), p.CreationDate) AS LastActivity,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
    ) t ON TRUE
    GROUP BY p.Id, p.Title
),
RankingPosts AS (
    SELECT 
        pm.PostId, 
        pm.Title, 
        pm.CommentCount,
        ROW_NUMBER() OVER (ORDER BY pm.CommentCount DESC) AS CommentRank,
        DENSE_RANK() OVER (ORDER BY pm.LastActivity DESC) AS ActivityRank
    FROM PostMetrics pm
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalViews,
    tu.AcceptedAnswers,
    rp.Title,
    rp.CommentCount,
    rp.CommentRank,
    rp.ActivityRank,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Votes v 
            WHERE v.VoteTypeId = 2 AND v.PostId = rp.PostId
        ) THEN 'Has Upvotes' 
        ELSE 'No Upvotes' 
    END AS VoteStatus
FROM TopUsers tu
JOIN RankingPosts rp ON tu.UserId = (
    SELECT p.OwnerUserId 
    FROM Posts p 
    WHERE p.Id = rp.PostId
)
ORDER BY tu.TotalViews DESC, rp.CommentCount DESC;
