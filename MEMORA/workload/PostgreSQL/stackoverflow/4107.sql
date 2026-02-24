
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(p.ViewCount) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.ViewCount) DESC) AS rn
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
HighScorePosts AS (
    SELECT 
        rp.Title,
        rp.Score,
        us.DisplayName,
        us.BadgeCount,
        us.Upvotes,
        us.Downvotes,
        us.TotalViews,
        rp.LastVoteDate
    FROM RecentPosts rp
    JOIN UserStats us ON rp.OwnerUserId = us.UserId
    WHERE rp.Score > 10
)
SELECT 
    hsp.Title,
    hsp.Score,
    hsp.DisplayName,
    hsp.BadgeCount,
    hsp.Upvotes,
    hsp.Downvotes,
    hsp.TotalViews,
    COALESCE(CAST(hsp.LastVoteDate AS CHAR), 'No Votes') AS LastVote
FROM HighScorePosts hsp
ORDER BY hsp.Score DESC, hsp.TotalViews DESC
LIMIT 10;
