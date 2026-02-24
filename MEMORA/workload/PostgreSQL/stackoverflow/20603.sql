
WITH RecentUserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY v.UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE((
            SELECT COUNT(c.Id)
            FROM Comments c
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        COALESCE((
            SELECT MAX(ph.CreationDate) 
            FROM PostHistory ph
            WHERE ph.PostId = p.Id 
            AND ph.PostHistoryTypeId IN (10, 11) 
        ), NULL) AS LastClosedDate,
        p.OwnerUserId
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
AggregatedPosts AS (
    SELECT 
        pd.PostId,
        pd.ViewCount,
        pd.CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY pd.PostId ORDER BY pd.ViewCount DESC) AS RankInViews,
        ROW_NUMBER() OVER (PARTITION BY pd.PostId ORDER BY pd.CommentCount DESC) AS RankInComments
    FROM PostDetails pd
    LEFT JOIN Votes v ON pd.PostId = v.PostId
    GROUP BY pd.PostId, pd.ViewCount, pd.CommentCount
),
FinalReport AS (
    SELECT 
        ap.PostId,
        pd.Title,
        pd.ViewCount,
        pd.CommentCount,
        ap.UpVotes,
        ap.DownVotes,
        CASE 
            WHEN pd.LastClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        COALESCE(ru.VoteCount, 0) AS RecentVotes,
        ap.RankInViews,
        ap.RankInComments
    FROM AggregatedPosts ap
    JOIN PostDetails pd ON ap.PostId = pd.PostId
    LEFT JOIN RecentUserVotes ru ON ru.UserId = pd.OwnerUserId
)
SELECT 
    PostId,
    Title,
    ViewCount,
    CommentCount,
    UpVotes,
    DownVotes,
    PostStatus,
    RecentVotes,
    CASE 
        WHEN RankInViews <= 10 THEN 'Top View'
        WHEN RankInComments <= 10 THEN 'Top Commented'
        ELSE 'Other'
    END AS Classification
FROM FinalReport
WHERE RecentVotes > 5
ORDER BY ViewCount DESC, CommentCount DESC
LIMIT 50;
