
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, u.DisplayName, u.Reputation
    HAVING COUNT(DISTINCT v.Id) > 5
),
ClosedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerName,
        pd.OwnerReputation,
        pd.LastClosedDate,
        pd.LastReopenedDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pd.PostId) AS CommentCount
    FROM PostDetails pd
    WHERE pd.LastClosedDate IS NOT NULL
),
ReopenedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerName,
        pd.OwnerReputation,
        pd.LastClosedDate,
        pd.LastReopenedDate
    FROM ClosedPosts cp
    JOIN PostDetails pd ON cp.PostId = pd.PostId
    WHERE pd.LastReopenedDate IS NOT NULL
)
SELECT 
    r.PostId,
    r.Title,
    r.OwnerName,
    r.OwnerReputation,
    cp.LastClosedDate,
    r.LastReopenedDate,
    COALESCE(cp.CommentCount, 0) AS ClosedComments,
    CASE 
        WHEN r.LastReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Still Closed'
    END AS Status,
    DENSE_RANK() OVER (PARTITION BY r.OwnerName ORDER BY r.LastReopenedDate DESC NULLS LAST) AS OwnerReopenRank
FROM ReopenedPosts r
LEFT JOIN ClosedPosts cp ON r.PostId = cp.PostId
ORDER BY r.LastReopenedDate DESC;
