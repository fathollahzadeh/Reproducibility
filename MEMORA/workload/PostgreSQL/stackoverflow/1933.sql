WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(A.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        (
            SELECT COUNT(*) 
            FROM Comments C 
            WHERE C.PostId = P.Id
        ) AS CommentCount
    FROM Posts P
    LEFT JOIN Posts A ON P.Id = A.AcceptedAnswerId
    WHERE P.PostTypeId = 1 
),
PopularUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        RANK() OVER (ORDER BY SUM(V.BountyAmount) DESC) AS RankByBounties,
        SUM(V.BountyAmount) AS TotalBounties
    FROM Users U
    JOIN Votes V ON U.Id = V.UserId
    WHERE V.VoteTypeId IN (8, 9) 
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    U.DisplayName AS UserName,
    U.BadgeCount,
    PI.Title,
    PI.Score,
    PI.ViewCount,
    PI.CommentCount,
    PU.RankByBounties,
    PU.TotalBounties,
    CASE 
        WHEN PI.AcceptedAnswerId != 0 THEN 'Has Accepted Answer' 
        ELSE 'No Accepted Answer' 
    END AS AnswerStatus
FROM UserBadges U
JOIN PostInfo PI ON U.UserId = PI.PostId
LEFT JOIN PopularUsers PU ON U.UserId = PU.UserId
WHERE U.BadgeCount > 0
ORDER BY PU.RankByBounties, U.BadgeCount DESC, PI.Score DESC;