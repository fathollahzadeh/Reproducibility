
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
    WHERE 
        PostCount > 0
),
PopularTags AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS TagPostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PT.Name AS PostType,
        U.DisplayName AS OwnerName,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, PT.Name, U.DisplayName
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation,
    PT.Title AS PopularPostTitle,
    PT.PostId,
    PT.CreationDate,
    PT.PostType,
    PT.CommentCount,
    PT.UpvoteCount,
    Tags.TagName AS PopularTag
FROM 
    TopUsers TU
JOIN 
    PostDetails PT ON PT.OwnerName = TU.DisplayName
JOIN 
    PopularTags Tags ON PT.Title LIKE '%' || Tags.TagName || '%'
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Reputation DESC, PT.UpvoteCount DESC, PT.CreationDate DESC;
