
WITH TagCount AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1
    GROUP BY TagName
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE P.PostTypeId = 1
    GROUP BY U.Id, U.DisplayName, U.Reputation
    ORDER BY TotalScore DESC
    LIMIT 10
),
Combined AS (
    SELECT 
        T.TagName,
        T.PostCount,
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.QuestionCount,
        U.TotalViews
    FROM TagCount T
    JOIN TopUsers U ON T.PostCount > 5
)
SELECT 
    C.TagName,
    C.PostCount,
    C.DisplayName AS TopUser,
    C.Reputation,
    C.QuestionCount,
    C.TotalViews
FROM Combined C
ORDER BY C.PostCount DESC, C.Reputation DESC;
