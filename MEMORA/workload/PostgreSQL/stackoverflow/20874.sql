
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.PostTypeId, p.Score, p.ViewCount
), FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.PostTypeId,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        (CASE 
            WHEN ps.Upvotes IS NULL THEN 0 
            ELSE ps.Upvotes 
        END) - (CASE 
            WHEN ps.Downvotes IS NULL THEN 0 
            ELSE ps.Downvotes 
        END) AS NetVotes,
        CASE 
            WHEN ps.PostTypeId IN (1, 2) THEN 'Question or Answer'
            ELSE 'Other'
        END AS PostCategory
    FROM PostStats ps
    WHERE ps.RowNum <= 10
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
)
SELECT 
    fp.PostId,
    fp.PostCategory,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.NetVotes,
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    ur.ReputationRank,
    CASE 
        WHEN fp.CommentCount = 0 AND fp.NetVotes < 0 THEN 
            'Needs Improvement'
        WHEN fp.NetVotes > 10 THEN 
            'Trending'
        ELSE 
            'Moderate Activity'
    END AS PostActivity
FROM FilteredPosts fp
JOIN Users u ON u.Id = fp.PostId 
JOIN UserReputation ur ON ur.UserId = u.Id
WHERE ur.BadgeCount > 0
ORDER BY fp.NetVotes DESC, ur.Reputation DESC;
