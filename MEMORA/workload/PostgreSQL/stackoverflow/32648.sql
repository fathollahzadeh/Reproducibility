WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE U.CreationDate <= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        COUNT(DISTINCT PH.Id) AS EditCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5)
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
UserPostSummary AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        UA.TotalScore,
        UA.CommentCount,
        PM.PostId,
        PM.Title,
        PM.CreationDate,
        PM.ViewCount,
        PM.Score,
        PM.TotalComments,
        PM.TotalVotes,
        RANK() OVER (PARTITION BY UA.UserId ORDER BY PM.CreationDate DESC) AS PostRank
    FROM UserActivity UA
    JOIN PostMetrics PM ON UA.UserId = PM.PostId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.Reputation,
    UPS.PostCount,
    UPS.TotalScore,
    UPS.CommentCount,
    UPS.PostId AS RecentPostId,
    UPS.Title AS RecentPostTitle,
    UPS.CreationDate AS RecentPostCreationDate,
    UPS.ViewCount AS RecentPostViewCount,
    UPS.Score AS RecentPostScore,
    UPS.TotalComments AS RecentPostTotalComments,
    UPS.TotalVotes AS RecentPostTotalVotes
FROM UserPostSummary UPS
WHERE UPS.PostRank = 1
ORDER BY UPS.Reputation DESC;