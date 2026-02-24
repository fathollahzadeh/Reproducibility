
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
),
PostRanked AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY (rp.UpVoteCount - rp.DownVoteCount) DESC) AS PopularityRank
    FROM RecentPosts rp
),
ClosedPosts AS (
    SELECT 
        p.Id,
        ph.CreationDate AS ClosedDate,
        c.Name AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN CloseReasonTypes c ON CAST(ph.Comment AS INTEGER) = c.Id
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    pr.PostId,
    pr.Title,
    pr.CreationDate,
    pr.OwnerDisplayName,
    pr.CommentCount,
    pr.UpVoteCount,
    pr.DownVoteCount,
    CASE 
        WHEN cp.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COALESCE(cp.CloseReason, 'N/A') AS CloseReason
FROM PostRanked pr
LEFT JOIN ClosedPosts cp ON pr.PostId = cp.Id
WHERE pr.PopularityRank <= 10
ORDER BY pr.PopularityRank;
