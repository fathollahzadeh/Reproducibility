
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (1, 2, 4) THEN 1 ELSE 0 END) AS PositiveVotes,
        SUM(CASE WHEN V.VoteTypeId IN (3, 10) THEN 1 ELSE 0 END) AS NegativeVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
), PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COALESCE(SUM(CASE WHEN C.Score IS NOT NULL THEN C.Score ELSE 0 END), 0) AS TotalCommentScore,
        COUNT(C.Id) AS TotalComments,
        COUNT(DISTINCT P2.Id) AS RelatedPosts
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN Posts P2 ON PL.RelatedPostId = P2.Id
    GROUP BY P.Id, P.Title, P.OwnerUserId
), ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
), UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(DISTINCT B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    U.DisplayName AS User,
    U.Reputation,
    UPS.VoteCount,
    UPS.UpVotes,
    UPS.DownVotes,
    UPS.PositiveVotes,
    UPS.NegativeVotes,
    PS.Title AS Post_Title,
    PS.TotalCommentScore,
    PS.TotalComments,
    COALESCE(ToC.Score, 0) AS Closed_Post_Count,
    UBC.BadgeCount,
    UBC.BadgeNames,
    PS.RelatedPosts
FROM Users U
JOIN UserVoteStats UPS ON U.Id = UPS.UserId
JOIN PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN (
    SELECT UserId, COUNT(PostId) AS Score
    FROM ClosedPosts
    WHERE rn = 1 
    GROUP BY UserId
) ToC ON U.Id = ToC.UserId
LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
WHERE U.Reputation > 100
AND UPS.PositiveVotes > UPS.NegativeVotes
ORDER BY U.Reputation DESC, PS.TotalCommentScore DESC;
