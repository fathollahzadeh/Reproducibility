WITH TagPopularity AS (
    SELECT 
        TagName,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        TagName
), 

UserEngagement AS (
    SELECT 
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvotesGiven,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvotesGiven,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.DisplayName
), 

PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        PH.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditRank
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
)

SELECT 
    TP.TagName,
    TP.TotalPosts,
    TP.QuestionCount,
    TP.AnswerCount,
    U.DisplayName,
    U.UpvotesGiven,
    U.DownvotesGiven,
    U.TotalScore,
    PA.PostId,
    PA.Title,
    PA.CreationDate,
    PA.ViewCount,
    PA.LastEditDate
FROM 
    TagPopularity TP
JOIN 
    UserEngagement U ON U.UpvotesGiven > 5 /* Interested in active users */
JOIN 
    PostActivity PA ON PA.EditRank = 1 /* Most recent edit for each post */
WHERE 
    TP.TotalPosts > 10 /* Only tags with more than 10 associated posts */
ORDER BY 
    TP.TotalPosts DESC, 
    U.TotalScore DESC, 
    PA.ViewCount DESC;
