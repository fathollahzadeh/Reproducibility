WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.AcceptedAnswerId, p.OwnerUserId
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS AnswerId,
        p.AcceptedAnswerId,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.AcceptedAnswerId ORDER BY u.Reputation DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 2 
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.LastActivityDate,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    (SELECT SUM(CASE WHEN bh.Class = 1 THEN 3 WHEN bh.Class = 2 THEN 2 WHEN bh.Class = 3 THEN 1 ELSE 0 END)
     FROM Badges bh 
     WHERE bh.UserId = pa.OwnerUserId) AS TotalBadgesScore,
    COALESCE((SELECT a.OwnerReputation FROM AcceptedAnswers a WHERE a.AcceptedAnswerId = pa.AcceptedAnswerId AND a.Rank = 1), -1) AS AcceptedAnswerReputation
FROM 
    PostActivity pa
WHERE 
    pa.rn = 1
ORDER BY 
    pa.LastActivityDate DESC
LIMIT 100;