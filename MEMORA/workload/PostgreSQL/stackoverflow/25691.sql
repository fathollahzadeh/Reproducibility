
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TagsCount AS (
    SELECT 
        tag.TagName,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount
    FROM 
        Tags tag
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || tag.TagName || '%'
    GROUP BY 
        tag.TagName
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.CommentCount,
        UA.UpvoteCount,
        UA.DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY UA.Reputation DESC) AS Rank
    FROM 
        UserActivity UA
    WHERE 
        UA.Reputation > 100
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.CommentCount,
    TU.UpvoteCount,
    TU.DownvoteCount,
    TC.TagName,
    TC.TotalPosts,
    TC.PopularPostCount
FROM 
    TopUsers TU
LEFT JOIN 
    TagsCount TC ON TU.QuestionCount > 0
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Reputation DESC, TC.TotalPosts DESC;
