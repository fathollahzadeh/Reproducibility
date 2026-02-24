
WITH RECURSIVE UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ur.DisplayName AS OwnerDisplayName,
        ur.Reputation AS OwnerReputation,
        ps.CloseCount,
        ps.ReopenCount
    FROM PostStatistics ps
    JOIN UserRankings ur ON ps.OwnerUserId = ur.UserId
    WHERE ps.CommentCount > 5 AND (ps.UpVotes - ps.DownVotes) > 10
),
TopPosts AS (
    SELECT 
        fp.*,
        ROW_NUMBER() OVER (ORDER BY (fp.UpVotes - fp.DownVotes) DESC) AS PostRank
    FROM FilteredPosts fp
)
SELECT 
    tp.PostId,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CloseCount,
    tp.ReopenCount
FROM TopPosts tp
WHERE tp.PostRank <= 100
ORDER BY (tp.UpVotes - tp.DownVotes) DESC;
