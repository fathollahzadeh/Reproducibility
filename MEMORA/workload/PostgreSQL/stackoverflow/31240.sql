
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    ph.ViewCount,
    ph.Score,
    ph.Level,
    COALESCE(AnswerCounts.AnswerCount, 0) AS TotalAnswers,
    COALESCE(TopVoter.DisplayName, 'No Votes') AS TopVoter,
    COALESCE(VotingStats.VoteCount, 0) AS TotalVotes,
    CASE 
        WHEN ph.Score > 0 THEN 'Popular'
        WHEN ph.Score < 0 THEN 'Unpopular'
        ELSE 'Neutral' 
    END AS PopularityLabel
FROM 
    PostHierarchy ph
LEFT JOIN 
    (SELECT 
         p.Id,
         COUNT(c.Id) AS AnswerCount
     FROM 
         Posts p
     LEFT JOIN 
         Posts c ON c.ParentId = p.Id
     WHERE 
         p.PostTypeId = 1
     GROUP BY 
         p.Id
    ) AS AnswerCounts ON AnswerCounts.Id = ph.PostId
LEFT JOIN 
    (SELECT 
         v.PostId,
         COUNT(v.Id) AS VoteCount,
         u.DisplayName
     FROM 
         Votes v
     LEFT JOIN 
         Users u ON v.UserId = u.Id
     GROUP BY 
         v.PostId, u.DisplayName
    ) AS VotingStats ON VotingStats.PostId = ph.PostId
LEFT JOIN 
    (SELECT 
         v.PostId,
         u.DisplayName
     FROM 
         Votes v
     JOIN 
         Users u ON v.UserId = u.Id
     GROUP BY 
         v.PostId, u.DisplayName
     HAVING 
         COUNT(v.Id) = (
             SELECT 
                 MAX(VoteCount)
             FROM 
                 (SELECT 
                      PostId, COUNT(*) AS VoteCount
                  FROM 
                      Votes
                  GROUP BY 
                      PostId) t
         )
    ) AS TopVoter ON TopVoter.PostId = ph.PostId
WHERE 
    ph.Level <= 2
ORDER BY 
    ph.CreationDate DESC
LIMIT 100;
