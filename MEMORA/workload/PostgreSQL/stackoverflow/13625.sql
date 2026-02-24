WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes
    FROM Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount,
        p.AnswerCount, p.CommentCount, p.FavoriteCount, p.OwnerUserId, u.DisplayName
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ps.PostId,
    ps.PostTypeId,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.CloseDate,
    ps.ReopenDate
FROM UserReputation ur
JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
WHERE ur.Reputation > 1000 
ORDER BY ps.Score DESC, ps.CreationDate DESC;