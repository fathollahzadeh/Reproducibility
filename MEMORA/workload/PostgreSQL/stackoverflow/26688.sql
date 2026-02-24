
WITH TagCounts AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1 
    GROUP BY TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagCounts
    WHERE PostCount > 10 
),
UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesReceived
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN Votes V ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        QuestionsAsked,
        AcceptedAnswers,
        UpvotesReceived,
        RANK() OVER (ORDER BY Reputation DESC, UpvotesReceived DESC) AS UserRank
    FROM UserStats
    WHERE Reputation > 1000 
)
SELECT
    T.TagName,
    T.PostCount,
    U.UserRank,
    U.DisplayName,
    U.Reputation,
    U.QuestionsAsked,
    U.AcceptedAnswers,
    U.UpvotesReceived
FROM TopTags T
JOIN TopUsers U ON U.QuestionsAsked > 0
ORDER BY T.PostCount DESC, U.Reputation DESC, U.UpvotesReceived DESC;
