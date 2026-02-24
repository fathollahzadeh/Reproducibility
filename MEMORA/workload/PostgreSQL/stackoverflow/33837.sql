WITH RecursiveUserPosts AS (
    
    SELECT 
        u.Id AS UserId,
        COALESCE(p.OwnerUserId, -1) AS PostOwnerUserId,
        COUNT(p.Id) AS PostsCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE EXISTS (
        SELECT 1 FROM Badges b WHERE b.UserId = u.Id
    )
    GROUP BY u.Id, p.OwnerUserId
), 
EnhancedPosts AS (
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(p.OwnerUserId, -1) AS PostOwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(DISTINCT v.UserId) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
    FROM Posts p
    LEFT JOIN RecursiveUserPosts rup ON p.OwnerUserId = rup.PostOwnerUserId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
      AND (p.AnswerCount IS NULL OR p.AnswerCount > 0) 
), 
FilteredPosts AS (
    
    SELECT 
        ep.PostId,
        ep.Title,
        ep.CreationDate,
        ep.ViewCount,
        ep.Score,
        ep.RecentPostRank,
        ep.CommentCount,
        ep.UpVoteCount,
        RANK() OVER (ORDER BY ep.ViewCount DESC, ep.Score DESC) AS PostRank
    FROM EnhancedPosts ep
    WHERE ep.RecentPostRank = 1 
)


SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.UpVoteCount,
    CASE 
        WHEN fp.Score > 50 THEN 'Highly Active'
        WHEN fp.Score BETWEEN 20 AND 50 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM FilteredPosts fp
WHERE fp.PostRank <= 10  
ORDER BY fp.ViewCount DESC;