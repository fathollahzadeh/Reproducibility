
WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Class,
        COUNT(*) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, B.Class
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        COALESCE(P.ParentId, 0) AS ParentId,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount
    FROM Posts P
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
),
UserPostCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    WHERE P.OwnerUserId IS NOT NULL
    GROUP BY P.OwnerUserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(AB.BadgeCount, 0) AS BadgeCount,
    COALESCE(PC.PostCount, 0) AS PostCount,
    COALESCE(PC.TotalScore, 0) AS TotalScore,
    PD.PostId,
    PD.Title,
    PD.Score,
    PD.CreationDate,
    PD.CommentCount,
    PD.UpVoteCount,
    PD.DownVoteCount,
    PH.LastEditDate,
    PH.HistoryTypes
FROM Users U
LEFT JOIN UserBadges AB ON U.Id = AB.UserId
LEFT JOIN UserPostCounts PC ON U.Id = PC.OwnerUserId
JOIN PostDetails PD ON PD.PostId = (SELECT Id FROM Posts WHERE OwnerUserId = U.Id ORDER BY CreationDate DESC LIMIT 1) 
JOIN PostHistoryDetails PH ON PD.PostId = PH.PostId
WHERE U.Reputation > 1000
AND (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 1) > 0
ORDER BY U.Reputation DESC, PD.Score DESC;
