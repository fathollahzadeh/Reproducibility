
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(T.Tags, ',')) AS TagName,
        COUNT(DISTINCT P.Id) AS TagCount
    FROM 
        Posts P
    JOIN 
        LATERAL (SELECT P.Tags) T ON TRUE
    GROUP BY 
        TagName
    HAVING 
        COUNT(DISTINCT P.Id) > 5
),
RecentEdits AS (
    SELECT 
        H.PostId,
        H.UserDisplayName,
        H.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY H.PostId ORDER BY H.CreationDate DESC) AS EditRank
    FROM 
        PostHistory H
    WHERE 
        H.PostHistoryTypeId IN (4, 5, 6) 
        AND H.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)
SELECT 
    PS.DisplayName AS UserName,
    PS.Reputation,
    COALESCE(TT.TagName, 'No Tags') AS Tag,
    PS.PostCount,
    PS.QuestionCount,
    PS.AcceptedAnswers,
    RE.UserDisplayName AS LastEditor,
    RE.CreationDate AS LastEditDate
FROM 
    UserStats PS
LEFT JOIN 
    TopTags TT ON PS.PostCount > 10 AND TT.TagCount > 5
LEFT JOIN 
    RecentEdits RE ON PS.UserId = RE.PostId AND RE.EditRank = 1
WHERE 
    PS.Reputation > 200 AND PS.QuestionCount > 5
ORDER BY 
    PS.Reputation DESC,
    PS.PostCount DESC
LIMIT 100;
