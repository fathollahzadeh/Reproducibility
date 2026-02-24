
WITH RecentUserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalBadges,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM RecentUserActivity
    WHERE TotalPosts > 10
),
ActiveTags AS (
    SELECT
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY T.Id, T.TagName
    ORDER BY PostCount DESC
    LIMIT 5
)

SELECT
    U.DisplayName AS TopUserDisplayName,
    U.Reputation AS TopUserReputation,
    U.TotalPosts AS TopUserTotalPosts,
    U.TotalComments AS TopUserTotalComments,
    A.TagName AS ActiveTagName,
    A.PostCount AS ActiveTagPostCount,
    A.TotalViews AS ActiveTagTotalViews
FROM TopUsers U
CROSS JOIN ActiveTags A
WHERE U.ReputationRank <= 10
ORDER BY U.Reputation DESC, A.PostCount DESC;
