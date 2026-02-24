
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
                 SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.Views,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.NetVotes,
    CASE 
        WHEN rp.CommentCount > 10 THEN 'Very Active'
        WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityLevel,
    CASE 
        WHEN rp.NetVotes > 50 THEN 'Highly Regarded'
        WHEN rp.NetVotes BETWEEN 20 AND 50 THEN 'Regarded'
        ELSE 'Needs Improvement'
    END AS ReputationLevel
FROM Users u
JOIN RankedPosts rp ON u.Id = rp.PostId
WHERE 
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId = u.Id AND b.Class = 1) > 0
    AND rp.PostRank = 1
ORDER BY u.Reputation DESC, rp.Score DESC;
