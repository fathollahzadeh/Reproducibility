
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN PT.Name = 'Answer' THEN 1 ELSE 0 END, 0)) AS AnswerCount,
        SUM(COALESCE(CASE WHEN PT.Name = 'Question' THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        MAX(P.CreationDate) AS LatestPostDate
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON POSITION(T.TagName IN P.Tags) > 0
    LEFT JOIN 
        PostTypes PT ON PT.Id = P.PostTypeId
    GROUP BY 
        T.TagName
),
MostActiveUsers AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN PT.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN PT.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostTypes PT ON PT.Id = P.PostTypeId
    GROUP BY 
        U.DisplayName, U.Reputation
    HAVING 
        COUNT(DISTINCT P.Id) > 5
),
FrequentEditors AS (
    SELECT 
        U.DisplayName,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        U.DisplayName
    HAVING 
        COUNT(PH.Id) > 10
),
FinalReport AS (
    SELECT 
        TS.TagName,
        TS.PostCount,
        TS.AnswerCount,
        TS.QuestionCount,
        TS.LatestPostDate,
        AU.DisplayName AS ActiveUser,
        EU.DisplayName AS Editor,
        EU.EditCount
    FROM 
        TagStatistics TS
    JOIN 
        (SELECT DisplayName, Reputation, PostCount, AnswerCount, QuestionCount
         FROM MostActiveUsers
         ORDER BY PostCount DESC
         LIMIT 1) AU ON TS.PostCount > 10
    JOIN 
        (SELECT DisplayName, EditCount
         FROM FrequentEditors
         ORDER BY EditCount DESC
         LIMIT 1) EU ON TS.PostCount > 5
)
SELECT 
    TagName,
    PostCount,
    AnswerCount,
    QuestionCount,
    LatestPostDate,
    ActiveUser,
    Editor,
    EditCount
FROM 
    FinalReport
ORDER BY 
    PostCount DESC, AnswerCount DESC;
