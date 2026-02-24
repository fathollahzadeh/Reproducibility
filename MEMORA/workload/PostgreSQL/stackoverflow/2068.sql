WITH UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM Votes v
    GROUP BY v.UserId
), 
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        DENSE_RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
), 
TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.AnswerCount,
        pm.CommentCount,
        pm.FavoriteCount,
        pha.LastChangeDate,
        pha.ChangeTypes,
        ROW_NUMBER() OVER (ORDER BY pm.ViewCount DESC) AS Rank
    FROM PostMetrics pm
    LEFT JOIN PostHistoryAggregates pha ON pm.PostId = pha.PostId
    ORDER BY pm.ViewCount DESC
)
SELECT 
    u.DisplayName,
    u.Reputation,
    tp.Title,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.FavoriteCount,
    COALESCE(uvc.TotalVotes, 0) AS UserVoteCount,
    COALESCE(uvc.UpVotes, 0) AS UserUpVotes,
    COALESCE(uvc.DownVotes, 0) AS UserDownVotes,
    tp.ChangeTypes,
    tp.LastChangeDate
FROM TopPosts tp
JOIN Users u ON u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN UserVoteCounts uvc ON uvc.UserId = u.Id
WHERE tp.Rank <= 10
ORDER BY tp.ViewCount DESC;