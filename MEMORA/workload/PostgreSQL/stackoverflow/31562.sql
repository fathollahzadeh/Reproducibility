
WITH RECURSIVE RecursivePosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.AcceptedAnswerId,
        a.CreationDate,
        a.Score,
        a.ViewCount,
        rp.Level + 1
    FROM Posts a
    JOIN RecursivePosts rp ON a.ParentId = rp.PostID
)

SELECT 
    u.Id AS UserID,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    SUM(CASE WHEN a.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
    SUM(COALESCE(COMMENT_COUNT.comment_count, 0)) AS TotalCommentCount,
    SUM(COALESCE(VOTE_COUNT.upvote_count, 0)) AS TotalUpVotes,
    SUM(COALESCE(VOTE_COUNT.downvote_count, 0)) AS TotalDownVotes
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
LEFT JOIN Posts a ON p.Id = a.ParentId  
LEFT JOIN (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS comment_count
    FROM Comments c
    GROUP BY c.PostId
) AS COMMENT_COUNT ON p.Id = COMMENT_COUNT.PostId
LEFT JOIN (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS downvote_count
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
) AS VOTE_COUNT ON p.Id = VOTE_COUNT.PostId
WHERE u.Reputation > 1000  
GROUP BY u.Id, u.DisplayName, u.Reputation
HAVING COUNT(DISTINCT p.Id) > 0  
ORDER BY u.Reputation DESC
LIMIT 10;
