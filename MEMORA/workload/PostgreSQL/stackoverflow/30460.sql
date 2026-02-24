WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        B.Name AS BadgeName, 
        B.Class,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
), 
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
), 
UserPostStats AS (
    SELECT 
        U.DisplayName AS UserName, 
        UPS.PostId, 
        UPS.Title,
        UPS.UpVotes, 
        UPS.DownVotes, 
        UPS.CommentCount,
        UPS.CloseCount,
        UPS.ReopenCount,
        (UPS.UpVotes - UPS.DownVotes) AS NetScore
    FROM 
        Users U
    JOIN 
        PostStats UPS ON U.Id = UPS.OwnerUserId
    WHERE 
        U.Reputation > 100 AND 
        (UPS.UpVotes - UPS.DownVotes) > 10 
)
SELECT 
    U.DisplayName, 
    U.Reputation, 
    U.LastAccessDate, 
    UPS.UserName,
    UPS.Title,
    UPS.NetScore,
    (SELECT STRING_AGG(BadgeName, ', ') 
     FROM UserBadges UB 
     WHERE UB.UserId = U.Id AND UB.BadgeRank <= 3) AS TopBadges 
FROM 
    Users U
JOIN 
    UserPostStats UPS ON U.DisplayName = UPS.UserName
WHERE 
    U.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
ORDER BY 
    UPS.NetScore DESC, U.Reputation DESC
LIMIT 10;