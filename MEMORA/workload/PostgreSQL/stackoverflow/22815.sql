
WITH UserAggregate AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(U.Reputation, 0)) AS TotalReputation,
        AVG(COALESCE(U.Views, 0)) AS AverageViews,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(U.Reputation, 0)) DESC) AS Rank
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        MAX(P.LastActivityDate) AS MostRecentActivity,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM Posts P
    LEFT JOIN Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
ClosedPostHistory AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS ClosedPostCount,
        STRING_AGG(DISTINCT CPR.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CPR ON PH.Comment = CPR.Id::TEXT
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.UserId
),
FinalSummary AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AverageScore,
        COALESCE(CP.ClosedPostCount, 0) AS ClosedPostCount,
        COALESCE(CP.CloseReasons, 'None') AS CloseReasons,
        UA.BadgeCount,
        UA.TotalReputation,
        UA.AverageViews
    FROM UserAggregate UA
    LEFT JOIN PostSummary PS ON UA.UserId = PS.OwnerUserId
    LEFT JOIN ClosedPostHistory CP ON UA.UserId = CP.UserId
)
SELECT 
    *,
    CASE 
        WHEN TotalPosts > 100 THEN 'High Poster'
        WHEN TotalPosts BETWEEN 50 AND 100 THEN 'Medium Poster'
        ELSE 'Low Poster'
    END AS PosterCategory,
    CASE 
        WHEN TotalReputation IS NULL OR TotalReputation = 0 THEN 'New User'
        WHEN TotalReputation < 1000 THEN 'Beginner'
        ELSE 'Experienced'
    END AS UserExperienceLevel,
    RANK() OVER (ORDER BY TotalReputation DESC) AS OverallRank
FROM FinalSummary
WHERE AverageScore > 0 OR ClosedPostCount > 0
ORDER BY TotalReputation DESC, TotalPosts DESC;
