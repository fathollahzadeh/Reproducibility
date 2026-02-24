WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS LatestActivity
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.UserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PHS.EditCount, 0) AS EditCount
    FROM 
        UserReputation U
    LEFT JOIN 
        PostStats PS ON U.UserId = PS.OwnerUserId
    LEFT JOIN 
        PostHistoryStats PHS ON U.UserId = PHS.UserId
)
SELECT 
    C.DisplayName,
    C.Reputation,
    C.TotalPosts,
    C.QuestionCount,
    C.AnswerCount,
    C.EditCount,
    CASE 
        WHEN C.Reputation > 5000 THEN 'Expert'
        WHEN C.Reputation BETWEEN 1000 AND 5000 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    CombinedStats C
ORDER BY 
    C.Reputation DESC, C.TotalPosts DESC
LIMIT 10;