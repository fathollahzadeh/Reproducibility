WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopens,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS PostDeletes,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.OwnerUserId
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    WHERE V.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY V.UserId
),
UserStatistics AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UBC.TotalBadges, 0) AS BadgeCount,
        COALESCE(PA.CommentCount, 0) AS CommentCount,
        COALESCE(RV.TotalVotes, 0) AS TotalVotes,
        COALESCE(RV.UpVotes, 0) AS UpVotes,
        COALESCE(RV.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN COALESCE(PA.CloseReopens, 0) + COALESCE(PA.PostDeletes, 0) > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS ActivityStatus
    FROM Users U
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN PostActivity PA ON U.Id = PA.OwnerUserId
    LEFT JOIN RecentVotes RV ON U.Id = RV.UserId
)
SELECT 
    U.DisplayName,
    U.BadgeCount,
    U.CommentCount,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    U.ActivityStatus
FROM UserStatistics U
WHERE U.BadgeCount > 0
  AND U.TotalVotes > 0
  AND U.CommentCount > (SELECT AVG(CommentCount) FROM UserStatistics)  
ORDER BY U.BadgeCount DESC, U.TotalVotes DESC
LIMIT 10;