
WITH RECURSIVE UserEngagement AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViewCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        RANK() OVER (ORDER BY COALESCE(SUM(P.ViewCount), 0) DESC) AS EngagementRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
RecentActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS PostHistoryCount,
        MAX(PH.CreationDate) AS LastActivityDate
    FROM Users U
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN PostHistory PH ON U.Id = PH.UserId
    GROUP BY U.Id, U.DisplayName
),
TopContributors AS (
    SELECT 
        UE.UserId,
        UE.DisplayName,
        UE.Reputation,
        UE.TotalViewCount,
        UE.TotalUpvotes,
        UE.TotalDownvotes,
        UA.CommentCount,
        UA.LastActivityDate
    FROM UserEngagement UE
    JOIN RecentActivity UA ON UE.UserId = UA.UserId
    WHERE UE.TotalPosts > 0
),
EngagementSummary AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        TotalViewCount,
        TotalUpvotes,
        TotalDownvotes,
        CommentCount,
        LastActivityDate,
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM TopContributors
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalViewCount,
    TotalUpvotes,
    TotalDownvotes,
    CommentCount,
    LastActivityDate,
    ReputationLevel,
    LEAD(LastActivityDate) OVER (ORDER BY LastActivityDate DESC) AS NextActivityDate
FROM EngagementSummary
ORDER BY TotalViewCount DESC, Reputation DESC
FETCH FIRST 10 ROWS ONLY;
