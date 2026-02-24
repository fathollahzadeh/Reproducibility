
WITH RecursivePostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(A.Id) AS AnswerCount,
        MAX(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END) AS HasComments,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.OwnerUserId
), 
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        AVG(P.Score) AS AvgScore
    FROM 
        Users U
    JOIN 
        Posts P ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        U.Id, U.Reputation
)
SELECT 
    R.PostId,
    R.Title,
    R.CreationDate,
    R.ViewCount,
    R.Score,
    R.AnswerCount,
    R.HasComments,
    U.UserId,
    U.Reputation AS UserReputation,
    U.QuestionCount,
    U.AvgScore,
    CASE 
        WHEN U.Reputation IS NULL THEN 'No Reputation' 
        ELSE 
            CASE 
                WHEN U.Reputation >= 1000 THEN 'High Reputation' 
                WHEN U.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation' 
                ELSE 'Low Reputation' 
            END 
    END AS ReputationLevel
FROM 
    RecursivePostStats R
LEFT JOIN 
    UserReputation U ON U.UserId = R.PostId
WHERE 
    R.ViewCount > 10
    AND R.AnswerCount >= 1
    AND R.UserPostRank <= 5
ORDER BY 
    R.Score DESC, R.ViewCount DESC
LIMIT 50;
