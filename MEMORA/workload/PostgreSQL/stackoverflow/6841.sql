WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersProvided,
        COUNT(DISTINCT C.Id) AS CommentsMade
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.CreationDate > '2020-01-01'
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        AnswersProvided,
        CommentsMade,
        RANK() OVER (ORDER BY QuestionsAsked DESC, AnswersProvided DESC, CommentsMade DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    U.DisplayName,
    U.QuestionsAsked,
    U.AnswersProvided,
    U.CommentsMade,
    U.UserRank,
    (SELECT STRING_AGG(T.TagName, ', ') FROM Tags T JOIN Posts Pt ON Pt.Tags LIKE '%' || T.TagName || '%' WHERE Pt.OwnerUserId = U.UserId) AS TagsAssociated
FROM 
    TopUsers U
WHERE 
    U.UserRank <= 10
ORDER BY 
    U.UserRank;
