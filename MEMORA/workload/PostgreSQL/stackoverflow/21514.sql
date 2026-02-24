
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation, UpVotes, DownVotes, PostCount, CommentCount, BadgeCount, TotalViews,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStatistics
),
MostActiveUsers AS (
    SELECT UserId, COUNT(*) AS ActivityCount
    FROM (
        SELECT U.Id AS UserId, P.CreationDate FROM Users U
        JOIN Posts P ON U.Id = P.OwnerUserId
        UNION ALL
        SELECT U.Id AS UserId, C.CreationDate FROM Users U
        JOIN Comments C ON U.Id = C.UserId
    ) AS UserActivity
    GROUP BY UserId
),
FinalReport AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TU.Reputation,
        TU.UpVotes,
        TU.DownVotes,
        TU.PostCount,
        TU.CommentCount,
        TU.BadgeCount,
        TU.TotalViews,
        COALESCE(MAU.ActivityCount, 0) AS ActivityCount
    FROM TopUsers TU
    LEFT JOIN MostActiveUsers MAU ON TU.UserId = MAU.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    UpVotes,
    DownVotes,
    PostCount,
    CommentCount,
    BadgeCount,
    TotalViews,
    ActivityCount,
    CASE 
        WHEN Reputation > 1000 THEN 'Expert'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel,
    CASE 
        WHEN TotalViews IS NULL OR TotalViews = 0 THEN 'Inactive'
        WHEN TotalViews > 10000 THEN 'Highly Active'
        ELSE 'Moderately Active'
    END AS ViewActivity,
    CONCAT('User: ', DisplayName, ', Reputation Level: ', 
        CASE 
            WHEN Reputation < 500 THEN 'Low'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'High'
        END) AS Remark
FROM FinalReport
WHERE ActivityCount > 0
ORDER BY Reputation DESC, ActivityCount DESC
LIMIT 50;
