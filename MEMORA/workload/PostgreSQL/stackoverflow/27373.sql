
WITH UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
        STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        unnest(string_to_array(P.Tags, '>')) AS T(TagName) ON TRUE
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditsMade,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TitleEdits,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosingActions
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
),
FinalStats AS (
    SELECT 
        UP.UserId,
        UP.DisplayName,
        UP.TotalPosts,
        UP.QuestionCount,
        UP.AnswerCount,
        UP.PopularPosts,
        UP.PositiveScoredPosts,
        UP.AssociatedTags,
        COALESCE(PHS.EditsMade, 0) AS EditsMade,
        COALESCE(PHS.TitleEdits, 0) AS TitleEdits,
        COALESCE(PHS.ClosingActions, 0) AS ClosingActions
    FROM 
        UserPosts UP
    LEFT JOIN 
        PostHistoryStats PHS ON UP.UserId = PHS.UserId
)
SELECT 
    *
FROM 
    FinalStats
WHERE 
    TotalPosts > 10
ORDER BY 
    UserId DESC, AnswerCount DESC;
