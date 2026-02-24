
WITH RECURSIVE UserRankings AS (
    SELECT 
        Id,
        Reputation,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PopularQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        COALESCE(COUNT(A.Id), 0) AS AnswerCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - P.CreationDate)) / 86400 AS AgeInDays
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND P.PostTypeId = 1  
    LEFT JOIN 
        Votes V ON V.PostId = P.Id AND V.VoteTypeId = 8 
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
HighScoring as (
    SELECT 
        P.Id,
        P.Score,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId IN (2, 3)) AS VoteCount 
    FROM 
        Posts P
    WHERE 
        P.Score IS NOT NULL
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UR.Rank,
    PQ.Title,
    PQ.CreationDate,
    PQ.AnswerCount,
    PQ.TotalBounty,
    H.Score AS PostScore,
    H.VoteCount AS PostVoteCount,
    CASE 
        WHEN PQ.TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus,
    CASE 
        WHEN AVG(H.Score) OVER () >= 100 THEN 'High Engagement'
        ELSE 'Normal Engagement'
    END AS EngagementLevel
FROM 
    Users U
JOIN 
    UserRankings UR ON U.Id = UR.Id
LEFT JOIN 
    PopularQuestions PQ ON PQ.AnswerCount > 5
LEFT JOIN 
    HighScoring H ON H.Id = PQ.QuestionId
WHERE 
    U.Reputation > 10000
    AND (U.Location IS NOT NULL OR U.WebsiteUrl IS NOT NULL)
    AND NOT EXISTS (
        SELECT 1 FROM Badges B WHERE B.UserId = U.Id AND B.Class = 1
    )
ORDER BY 
    UR.Rank, PQ.TotalBounty DESC
LIMIT 50;
