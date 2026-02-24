
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN PT.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PT.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        * 
    FROM 
        UserReputation 
    WHERE 
        Reputation > 1000 
    ORDER BY 
        Reputation DESC 
    LIMIT 10
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViewCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName 
    HAVING 
        COUNT(DISTINCT P.Id) > 5
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        PH.PostId
)

SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TS.TagName,
    TS.PostCount AS TagPostCount,
    TS.AvgViewCount,
    PHS.EditCount,
    PHS.LastEditDate
FROM 
    TopUsers TU
JOIN 
    TagStats TS ON TU.QuestionCount > 2
JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
LEFT JOIN 
    PostHistorySummary PHS ON P.Id = PHS.PostId
WHERE 
    P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
ORDER BY 
    TU.Reputation DESC, TS.PostCount DESC;
