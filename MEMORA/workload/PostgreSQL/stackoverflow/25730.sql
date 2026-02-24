
WITH TagCounts AS (
    SELECT
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1  
    GROUP BY
        Tag
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Comments C ON U.Id = C.UserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagCounts
)
SELECT
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.QuestionsAsked,
    U.CommentsMade,
    U.UpvotesReceived,
    U.DownvotesReceived,
    T.Tag,
    T.PostCount
FROM
    UserReputation U
JOIN
    TopTags T ON U.Reputation >= 1000  
WHERE
    T.Rank <= 5  
ORDER BY
    U.Reputation DESC, T.PostCount DESC;
