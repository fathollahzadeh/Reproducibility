WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        LastAccessDate, 
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS ReputationLevel
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId, p.CreationDate, p.LastActivityDate
),
TopThreePosts AS (
    SELECT 
        rp.*, 
        ur.ReputationLevel,
        COALESCE(ur.Reputation, 0) AS UserReputation
    FROM RecentPosts rp
    LEFT JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE rp.UserPostRank <= 3
)
SELECT 
    tp.PostId, 
    tp.OwnerUserId, 
    tp.PostTypeId, 
    tp.CreationDate, 
    tp.LastActivityDate, 
    tp.CommentCount, 
    tp.UpVotes,
    tp.DownVotes,
    tp.ReputationLevel,
    CASE 
        WHEN tp.UpVotes > tp.DownVotes THEN 'Positive' 
        WHEN tp.UpVotes < tp.DownVotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS PostSentiment,
    CASE 
        WHEN tp.UserReputation IS NULL THEN 'New User'
        WHEN tp.UserReputation < 100 THEN 'Low Reputation User'
        ELSE 'Established User'
    END AS UserReputationCategory,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.OwnerUserId = tp.OwnerUserId AND p2.CreationDate < tp.CreationDate) AS PostsBeforeCurrent,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p3 ON p3.Tags LIKE '%' || t.TagName || '%' 
     WHERE p3.Id = tp.PostId) AS TagsUsed
FROM TopThreePosts tp
WHERE tp.PostTypeId IN (1, 2) 
  AND tp.LastActivityDate IS NOT NULL 
ORDER BY tp.LastActivityDate DESC;