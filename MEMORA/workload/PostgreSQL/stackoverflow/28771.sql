WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT A.Id) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Posts A ON P.Id = A.ParentId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
TagUsage AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY T.Id, T.TagName
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS ChangesMade,
        MAX(PH.CreationDate) AS LastChangeDate
    FROM PostHistory PH
    GROUP BY PH.UserId
)
SELECT 
    U.DisplayName,
    UPS.TotalPosts,
    UPS.TotalAnswers,
    UPS.TotalViews,
    UPS.TotalUpvotes,
    UPS.TotalDownvotes,
    (SELECT COUNT(*) FROM TagUsage) AS TotalTags,
    (SELECT COUNT(*) FROM PostHistorySummary) AS TotalEditors,
    (SELECT COUNT(DISTINCT P.Id) FROM Posts P WHERE P.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')) AS RecentPosts,
    (SELECT COUNT(*) FROM Votes V WHERE V.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month')) AS RecentVotes
FROM UserPostStats UPS
JOIN Users U ON U.Id = UPS.UserId
ORDER BY UPS.TotalPosts DESC
LIMIT 10;