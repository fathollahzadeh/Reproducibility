
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        RANK() OVER (ORDER BY pd.Score DESC) AS ScoreRank
    FROM PostDetails pd
    WHERE pd.CommentCount > 10
)
SELECT 
    u.DisplayName,
    ur.ReputationCategory,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.Score >= 100 THEN 'High Engagement'
        WHEN tp.Score BETWEEN 50 AND 99 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM TopPosts tp
JOIN Users u ON tp.PostId = u.Id
JOIN UserReputation ur ON u.Id = ur.Id
WHERE ur.ReputationCategory = 'High'
ORDER BY tp.Score DESC
FETCH FIRST 10 ROWS ONLY;
