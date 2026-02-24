WITH TagStats AS (
    SELECT
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS ContributingUsers
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE T.Count > 50 
    GROUP BY T.TagName
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT
        TS.TagName,
        TS.PostCount,
        TS.TotalViews,
        TS.AverageScore,
        TS.ContributingUsers,
        RANK() OVER (ORDER BY TS.TotalViews DESC) AS TagRank
    FROM TagStats TS
),
TopUsers AS (
    SELECT
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.PostCount,
        UR.TotalViews,
        RANK() OVER (ORDER BY UR.Reputation DESC) AS UserRank
    FROM UserReputation UR
)
SELECT
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.AverageScore,
    T.ContributingUsers,
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation
FROM TopTags T
JOIN TopUsers U ON T.TagRank = U.UserRank
WHERE T.TagRank <= 5 AND U.UserRank <= 5
ORDER BY T.TotalViews DESC, U.Reputation DESC;