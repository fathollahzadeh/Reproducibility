
WITH TagFrequency AS (
    SELECT 
        unnest(string_to_array(trim(both '<>' from Tags), '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesGiven,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesGiven
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostInsights AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(A.AcceptedAnswerId, 0) AS AcceptedAnswer,
        COALESCE(PH.TagList, '{}') AS TagsList,
        COALESCE(PH.CommentCount, 0) AS CommentsMade
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN (
        SELECT 
            C.PostId, 
            COUNT(*) AS CommentCount,
            ARRAY_AGG(DISTINCT trim(both '<>' from Tags)) AS TagList
        FROM 
            Comments C
        JOIN 
            Posts P ON C.PostId = P.Id
        WHERE 
            P.PostTypeId = 1
        GROUP BY 
            C.PostId
    ) PH ON P.Id = PH.PostId
    WHERE 
        P.PostTypeId = 1
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.QuestionsAsked,
    U.CommentsMade,
    U.UpVotesGiven,
    U.DownVotesGiven,
    COUNT(DISTINCT PI.PostId) AS PostsInCategory,
    COUNT(DISTINCT TF.TagName) AS UniqueTagsUsed
FROM 
    UserActivity U
LEFT JOIN 
    PostInsights PI ON U.UserId = PI.AcceptedAnswer
LEFT JOIN 
    TagFrequency TF ON TF.TagName = ANY(PI.TagsList)
GROUP BY 
    U.UserId, U.DisplayName, U.QuestionsAsked, U.CommentsMade, U.UpVotesGiven, U.DownVotesGiven
ORDER BY 
    U.QuestionsAsked DESC, U.UpVotesGiven DESC;
