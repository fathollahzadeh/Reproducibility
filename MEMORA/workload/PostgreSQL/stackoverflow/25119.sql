
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, char_length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1  
    GROUP BY TagName
),
MostPopularTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagCounts
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotesReceived
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        CommentsMade,
        TotalVotesReceived,
        RANK() OVER (ORDER BY TotalVotesReceived DESC) AS UserRank
    FROM UserActivity
)
SELECT 
    T.TagName,
    T.PostCount,
    U.UserId,
    U.DisplayName,
    U.QuestionsAsked,
    U.CommentsMade,
    U.TotalVotesReceived
FROM MostPopularTags T
JOIN TopUsers U ON U.QuestionsAsked > 5  
WHERE T.TagRank <= 10  
ORDER BY T.PostCount DESC, U.TotalVotesReceived DESC;
