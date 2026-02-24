
WITH RECURSIVE UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS Comments,
        COALESCE(v.VoteCount, 0) AS Upvotes,
        COALESCE(cl.CommentText, 'No close reason') AS CloseReason
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON c.PostId = p.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) v ON v.PostId = p.Id
    LEFT JOIN 
        (SELECT ph.PostId, STRING_AGG(cr.Name, ', ') AS CommentText
         FROM PostHistory ph
         INNER JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
         WHERE ph.PostHistoryTypeId = 10
         GROUP BY ph.PostId) cl ON cl.PostId = p.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    c.PostCount,
    c.TotalScore,
    p.Title,
    p.CreationDate,
    p.Score,
    p.Comments,
    p.Upvotes,
    p.CloseReason
FROM 
    Users u
JOIN 
    UserPostCounts c ON c.UserId = u.Id
JOIN 
    PostDetails p ON p.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    c.PostCount DESC, 
    c.TotalScore DESC,
    p.CreationDate DESC
LIMIT 10;
