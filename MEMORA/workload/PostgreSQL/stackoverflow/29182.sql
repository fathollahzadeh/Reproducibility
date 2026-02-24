
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AvgScore,
        MAX(P.ViewCount) AS MaxViews,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        T.TagName
    FROM 
        PostHistory PH
    JOIN 
        Tags T ON CAST(PH.Comment AS INT) = T.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
    ORDER BY 
        PH.CreationDate DESC
),
ActiveQuestions AS (
    SELECT 
        P.Id,
        P.Title,
        COALESCE(PH.CreationDate, P.CreationDate) AS LastActivityDate,
        P.ViewCount,
        T.TagName
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11) 
    JOIN 
        UNNEST(STRING_TO_ARRAY(P.Tags, ',')) AS TagArray ON TRUE 
    JOIN 
        Tags T ON T.TagName = TagArray
    WHERE 
        P.PostTypeId = 1 
        AND (PH.PostHistoryTypeId IS NULL OR PH.PostHistoryTypeId = 11) 
)

SELECT 
    TS.TagName,
    TS.PostCount,
    TS.QuestionCount,
    TS.AnswerCount,
    TS.AvgScore,
    TS.MaxViews,
    TS.ActiveUsers,
    COUNT(DISTINCT CP.PostId) AS ClosedPostCount,
    COUNT(DISTINCT AQ.Id) AS ActiveQuestionCount,
    STRING_AGG(DISTINCT AQ.Title, '; ') AS RecentActiveQuestions
FROM 
    TagStats TS
LEFT JOIN 
    ClosedPosts CP ON CP.TagName = TS.TagName
LEFT JOIN 
    ActiveQuestions AQ ON AQ.TagName = TS.TagName
GROUP BY 
    TS.TagName, TS.PostCount, TS.QuestionCount, TS.AnswerCount, TS.AvgScore, TS.MaxViews, TS.ActiveUsers
ORDER BY 
    TS.PostCount DESC;
