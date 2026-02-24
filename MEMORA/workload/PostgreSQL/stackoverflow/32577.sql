
WITH RECURSIVE PostViews AS (
    SELECT 
        p.Id, 
        COUNT(v.Id) AS VoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
    GROUP BY p.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(p.Tags, '>')) AS TagName
    ) AS t ON TRUE
    GROUP BY u.Id, u.DisplayName
),
TaggedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(th.PostCount, 0) AS TagPostCount,
        vp.VoteCount,
        vp.Upvotes,
        vp.Downvotes
    FROM Posts p
    LEFT JOIN (
        SELECT 
            t.Id,
            COUNT(DISTINCT p.Id) AS PostCount
        FROM Tags t
        LEFT JOIN Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
        GROUP BY t.Id
    ) AS th ON th.Id = p.Id
    LEFT JOIN PostViews vp ON vp.Id = p.Id
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '6 months'
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.CommentCount,
    u.TotalViews,
    p.Title,
    p.TagPostCount,
    p.VoteCount,
    p.Upvotes,
    p.Downvotes
FROM UserEngagement u
CROSS JOIN TaggedPosts p
ORDER BY 
    u.TotalViews DESC,
    p.TagPostCount DESC
LIMIT 100;
