WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        CreationDate, 
        LastAccessDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
),
HighestRatedPosts AS (
    SELECT 
        pd.*, 
        RANK() OVER (ORDER BY pd.UpVoteCount DESC, pd.CommentCount DESC) AS PostRank
    FROM PostDetails pd
)
SELECT 
    u.UserId,
    u.Reputation,
    u.ReputationRank,
    h.PostId,
    h.Title,
    h.OwnerDisplayName,
    h.UpVoteCount,
    h.CommentCount,
    CASE 
        WHEN h.PostRank <= 10 THEN 'Top 10'
        ELSE 'Others' 
    END AS PostCategory,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = h.PostId AND v.UserId = u.UserId AND v.VoteTypeId = 2) THEN 'Voted Up'
        ELSE 'Not Voted Up' 
    END AS UserVoteStatus
FROM UserReputation u
LEFT JOIN HighestRatedPosts h ON u.UserId = h.OwnerUserId
WHERE u.Reputation > 1000
ORDER BY u.Reputation DESC, h.UpVoteCount DESC, h.CommentCount DESC;
