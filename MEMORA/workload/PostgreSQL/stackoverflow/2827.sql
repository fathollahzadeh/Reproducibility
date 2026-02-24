
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank 
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
),
ClosingReasons AS (
    SELECT 
        PH.PostId,
        ARRAY_AGG(DISTINCT CR.Name) AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON CAST(PH.Comment AS INT) = CR.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        PH.PostId
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.TotalScore,
    UA.QuestionCount,
    UA.AnswerCount,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    CR.CloseReasons
FROM 
    UserActivity UA
LEFT JOIN 
    RecentPosts RP ON UA.UserId = RP.OwnerUserId AND RP.RecentRank = 1
LEFT JOIN 
    ClosingReasons CR ON RP.Id = CR.PostId
WHERE 
    UA.Reputation > 1000
ORDER BY 
    UA.TotalScore DESC, UA.DisplayName ASC
LIMIT 50;
