
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.LastAccessDate,
        CASE 
            WHEN U.Reputation >= 1000 THEN 'Gold'
            WHEN U.Reputation BETWEEN 500 AND 999 THEN 'Silver'
            ELSE 'Bronze'
        END AS ReputationTier
    FROM 
        Users U
), PostSummary AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ViewCount, 
        P.AnswerCount, 
        P.CreationDate, 
        U.DisplayName AS OwnerDisplayName,
        COALESCE(PH.RevisionCount, 0) AS RevisionCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT PH.PostId, COUNT(*) AS RevisionCount
        FROM PostHistory PH
        GROUP BY PH.PostId
    ) PH ON PH.PostId = P.Id
    JOIN Users U ON P.OwnerUserId = U.Id
),
TopPosts AS (
    SELECT 
        PS.PostId, 
        PS.Title, 
        PS.ViewCount, 
        PS.AnswerCount, 
        PS.CreationDate, 
        PS.OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY PS.OwnerDisplayName ORDER BY PS.ViewCount DESC) AS Rank
    FROM 
        PostSummary PS
    WHERE 
        PS.ViewCount IS NOT NULL AND 
        PS.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
)
SELECT 
    UP.DisplayName, 
    UP.Reputation, 
    TP.Title, 
    TP.ViewCount, 
    TP.AnswerCount, 
    TP.CreationDate,
    UP.ReputationTier,
    CASE 
        WHEN TP.AnswerCount = 0 THEN 'No Answers Yet' 
        ELSE 'Has Answers' 
    END AS AnswerStatus
FROM 
    UserReputation UP
JOIN 
    TopPosts TP ON UP.UserId = (
        SELECT P.OwnerUserId 
        FROM Posts P 
        WHERE P.Id = TP.PostId
    )
WHERE 
    UP.Reputation >= (
        SELECT AVG(Reputation) 
        FROM UserReputation
    )
ORDER BY 
    UP.Reputation DESC, 
    TP.ViewCount DESC
LIMIT 10;
