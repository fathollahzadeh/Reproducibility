
WITH UsersWithBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class AS BadgeClass,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, B.Name, B.Class
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.CreationDate, P.AcceptedAnswerId, P.OwnerUserId
),
TopUsers AS (
    SELECT 
        P.OwnerUserId,
        SUM(P.Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(P.Score) DESC) AS UserRank
    FROM Posts P
    WHERE P.PostTypeId = 1
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    U.LastAccessDate,
    COUNT(DISTINCT B.BadgeName) AS UniqueBadges,
    SUM(CASE WHEN B.BadgeClass = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN B.BadgeClass = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN B.BadgeClass = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
    PS.PostId,
    PS.Title AS PostTitle,
    PS.CreationDate AS PostCreationDate,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes,
    (SELECT COUNT(*) FROM Posts WHERE AcceptedAnswerId = PS.PostId) AS RelatedQuestionsCount,
    SU.TotalScore AS UserScore,
    SU.UserRank
FROM Users U
LEFT JOIN UsersWithBadges B ON U.Id = B.UserId
LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN TopUsers SU ON U.Id = SU.OwnerUserId
GROUP BY U.Id, U.DisplayName, U.Reputation, U.LastAccessDate, PS.PostId, PS.Title, PS.CreationDate, PS.CommentCount, PS.UpVotes, PS.DownVotes, SU.TotalScore, SU.UserRank
HAVING COUNT(DISTINCT B.BadgeName) > 0
ORDER BY SU.UserRank, U.Reputation DESC;
