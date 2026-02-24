WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts 
        WHERE PostTypeId = 2 
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ur.Reputation,
    ur.ReputationRank,
    CASE 
        WHEN ps.ViewCount < 100 THEN 'Low Views'
        WHEN ps.ViewCount BETWEEN 100 AND 1000 THEN 'Moderate Views'
        ELSE 'High Views' 
    END AS ViewCategory,
    (SELECT COUNT(*) 
        FROM Votes v 
        WHERE v.PostId = ps.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) 
        FROM Votes v 
        WHERE v.PostId = ps.PostId AND v.VoteTypeId = 3) AS DownvoteCount
FROM 
    PostStats ps
JOIN 
    UserReputation ur ON ps.PostId = ur.UserId
WHERE 
    ps.UserPostRank <= 5
ORDER BY 
    ps.Score DESC, 
    ps.CreationDate DESC;
