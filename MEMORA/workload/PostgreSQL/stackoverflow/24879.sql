
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
HighRepUsers AS (
    SELECT 
        Id,
        Reputation
    FROM UserReputation
    WHERE ReputationRank <= 100
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.Title,
        rp.CommentCount,
        rp.VoteCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        u.DisplayName,
        rp.PostId,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY rp.VoteCount DESC) AS UserPostRank
    FROM RecentPosts rp
    JOIN Users u ON u.Id = rp.OwnerUserId
    WHERE u.Reputation > 500
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CommentCount,
        tp.VoteCount,
        tp.UpVoteCount,
        tp.DownVoteCount,
        tp.DisplayName,
        CASE 
            WHEN tp.UpVoteCount >= tp.DownVoteCount THEN 'Positive'
            ELSE 'Negative'
        END AS Sentiment,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM TopPosts tp
    LEFT JOIN Posts p ON p.Id = tp.PostId
    WHERE tp.UserPostRank = 1
    ORDER BY tp.VoteCount DESC
)
SELECT 
    ps.Title,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.DisplayName,
    ps.Sentiment,
    ps.PostStatus,
    COALESCE((SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM Tags t 
        WHERE t.WikiPostId = ps.PostId), 'No Tags') AS Tags,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.AcceptedAnswerId = ps.PostId) AS AnsweredCount
FROM PostStatistics ps
WHERE ps.PostStatus = 'Open'
ORDER BY ps.VoteCount DESC
LIMIT 10;
