
WITH RECURSIVE RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.PostTypeId,
        1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  
    UNION ALL
    SELECT 
        A.Id AS PostId,
        A.Title,
        A.OwnerUserId,
        A.CreationDate,
        A.PostTypeId,
        R.Level + 1
    FROM Posts A
    INNER JOIN RecursiveCTE R ON A.ParentId = R.PostId
    WHERE R.PostTypeId = 1
),
VoteCounts AS (
    SELECT 
        PostId, 
        COUNT(*) FILTER (WHERE VoteTypeId = 2) AS Upvotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS Downvotes
    FROM Votes
    GROUP BY PostId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostScore AS (
    SELECT 
        P.Id AS PostId,
        (COALESCE(VC.Upvotes, 0) - COALESCE(VC.Downvotes, 0)) AS Score,
        P.CreationDate
    FROM Posts P
    LEFT JOIN VoteCounts VC ON P.Id = VC.PostId
)
SELECT 
    R.Level,
    R.Title,
    U.DisplayName AS Owner,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    PS.Score,
    R.CreationDate
FROM RecursiveCTE R
JOIN Users U ON R.OwnerUserId = U.Id
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN PostScore PS ON R.PostId = PS.PostId
WHERE R.Level = 1  
AND PS.Score >= 0  
ORDER BY PS.Score DESC, R.CreationDate DESC;
