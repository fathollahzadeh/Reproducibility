
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COUNT(DISTINCT A.Id) AS AnswersProvided,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostsCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    ORDER BY 
        PostsCount DESC
    LIMIT 10
),
UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    UR.QuestionsAsked,
    UR.AnswersProvided,
    UR.UpvotesReceived,
    UR.DownvotesReceived,
    UBC.BadgeCount,
    TT.TagName,
    TT.PostsCount,
    TT.QuestionsCount,
    TT.AnswersCount
FROM 
    UserReputation UR
JOIN 
    UserBadgeCount UBC ON UR.UserId = UBC.UserId
JOIN 
    TopTags TT ON TT.QuestionsCount > 0
ORDER BY 
    UR.Reputation DESC,
    UBC.BadgeCount DESC
FETCH FIRST 20 ROWS ONLY;
