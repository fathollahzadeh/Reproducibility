WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        DisplayName, 
        Reputation, 
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank 
    FROM Users
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId, 
        p.Title, 
        p.CreationDate, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts
    FROM Posts p 
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        pm.PostId, 
        pm.Title, 
        pm.OwnerUserId, 
        pm.CreationDate, 
        pm.UpVotes, 
        pm.DownVotes, 
        pm.CommentCount, 
        ur.DisplayName AS OwnerName,
        ur.ReputationRank
    FROM PostMetrics pm
    JOIN UserReputation ur ON pm.OwnerUserId = ur.UserId
    WHERE pm.UpVotes - pm.DownVotes > 0
    ORDER BY pm.UpVotes - pm.DownVotes DESC
    LIMIT 10
)

SELECT 
    tp.Title, 
    tp.OwnerName, 
    tp.UpVotes, 
    tp.DownVotes, 
    tp.CommentCount, 
    CASE 
        WHEN tp.ReputationRank <= 10 THEN 'Top Influencer' 
        ELSE 'Community Member' 
    END AS UserType
FROM TopPosts tp
LEFT JOIN Posts p ON tp.PostId = p.Id
WHERE p.ClosedDate IS NULL
AND p.AnswerCount > 0
ORDER BY tp.UpVotes DESC, tp.CommentCount DESC;