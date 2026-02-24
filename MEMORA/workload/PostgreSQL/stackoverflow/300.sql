
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS VoteCount,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ARRAY_AGG(DISTINCT COALESCE(t.TagName, 'Unlabeled')) AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN LATERAL unnest(string_to_array(p.Tags, '>')) AS tag ON TRUE
    LEFT JOIN Tags t ON t.TagName = tag
    WHERE p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.VoteCount,
        ua.PostCount,
        ua.CommentCount,
        ROW_NUMBER() OVER (ORDER BY ua.Reputation DESC) AS Rank
    FROM UserActivity ua
    WHERE ua.PostCount > 0
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseReasonCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY p.Id
    HAVING COUNT(ph.Id) > 0
)
SELECT 
    pu.UserId,
    pu.DisplayName,
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.Score,
    ps.Tags,
    ps.CommentCount,
    ps.Upvotes,
    ps.Downvotes,
    cp.CloseReasonCount,
    cp.LastClosedDate,
    pu.Rank AS UserRank
FROM TopUsers pu
JOIN PostStats ps ON pu.UserId = ps.PostId
LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
WHERE pu.Rank <= 10
ORDER BY pu.Reputation DESC, ps.PostRank;
