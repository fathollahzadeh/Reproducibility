
WITH UserVoteCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation,
        CASE 
            WHEN ph.PostId IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM Posts p
    LEFT JOIN Users U ON p.OwnerUserId = U.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN Badges b ON U.Id = b.UserId
    GROUP BY p.Id, U.DisplayName, U.Reputation, ph.PostId
),
RankedPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (PARTITION BY pd.PostStatus ORDER BY pd.Score DESC) AS RankWithinStatus
    FROM PostDetails pd
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Reputation,
    rp.Score,
    rp.CommentCount,
    rp.PostStatus,
    rp.RankWithinStatus,
    COALESCE(uv.UpVotes, 0) AS UserUpVotes,
    COALESCE(uv.DownVotes, 0) AS UserDownVotes
FROM RankedPosts rp
LEFT JOIN UserVoteCounts uv ON rp.OwnerDisplayName = (SELECT U.DisplayName FROM Users U WHERE U.Id = uv.UserId)
WHERE rp.RankWithinStatus <= 5
ORDER BY rp.PostStatus, rp.RankWithinStatus;
