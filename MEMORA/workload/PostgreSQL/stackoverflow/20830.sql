
WITH RecursivePostHistories AS (
    SELECT Ph.PostId, Ph.PostHistoryTypeId, Ph.CreationDate, Ph.UserId,
           ROW_NUMBER() OVER (PARTITION BY Ph.PostId ORDER BY Ph.CreationDate DESC) AS rn
    FROM PostHistory Ph
    WHERE Ph.PostHistoryTypeId IN (10, 11) 
),
PostScoreStats AS (
    SELECT P.Id AS PostId, 
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
           COUNT(DISTINCT C.Id) AS CommentCount,
           COUNT(DISTINCT B.Id) AS BadgeCount,
           COUNT(DISTINCT PL.RelatedPostId) AS LinkedPostCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    GROUP BY P.Id
),
ActiveUsers AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           SUM(Ps.Upvotes - Ps.Downvotes) AS UserScore,
           COUNT(P.Id) AS TotalPosts
    FROM Users U
    LEFT JOIN PostScoreStats Ps ON Ps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
    HAVING COUNT(P.Id) > 5 
),
PostDetails AS (
    SELECT P.Id, P.Title, P.CreationDate, PHC.CreationDate AS ClosestClose,
           PHO.CreationDate AS ClosestOpen, PS.Upvotes, PS.Downvotes,
           PS.CommentCount, PS.BadgeCount, PS.LinkedPostCount,
           COALESCE(PH.UserId, -1) AS LastHistoryUserId,
           ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY COALESCE(PH.UserId, -1)) AS LastActionUserRank
    FROM Posts P
    LEFT JOIN RecursivePostHistories PH ON P.Id = PH.PostId
    LEFT JOIN PostScoreStats PS ON P.Id = PS.PostId
    LEFT JOIN RecursivePostHistories PHC ON PHC.PostId = P.Id AND PHC.PostHistoryTypeId = 10 
    LEFT JOIN RecursivePostHistories PHO ON PHO.PostId = P.Id AND PHO.PostHistoryTypeId = 11 
)
SELECT PD.Id AS PostID,
       PD.Title,
       PD.CreationDate AS PostDate,
       PD.ClosestClose,
       PD.ClosestOpen,
       PD.Upvotes,
       PD.Downvotes,
       PD.CommentCount,
       PD.BadgeCount,
       PD.LinkedPostCount,
       U.DisplayName AS LastActionUser, 
       CASE
           WHEN PD.LastActionUserRank = 1 THEN 'Latest Action'
           ELSE 'Earlier Action'
       END AS ActionType,
       CASE 
           WHEN U.UserId IS NOT NULL AND PD.LastHistoryUserId > 0 THEN 'Has Activity'
           ELSE 'No Activity' 
       END AS UserActivityStatus
FROM PostDetails PD
LEFT JOIN ActiveUsers U ON PD.LastHistoryUserId = U.UserId
WHERE PD.ClosestClose IS NOT NULL
ORDER BY PD.ClosestClose DESC,
         PD.Upvotes DESC,
         PD.CommentCount DESC
LIMIT 100;
