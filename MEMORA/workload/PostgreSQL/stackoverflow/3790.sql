WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        CreationDate, 
        LastAccessDate, 
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostVoteCounts AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(PVC.UpVotes, 0) AS UpVotes,
        COALESCE(PVC.DownVotes, 0) AS DownVotes,
        (COALESCE(PVC.UpVotes, 0) - COALESCE(PVC.DownVotes, 0)) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY (COALESCE(PVC.UpVotes, 0) - COALESCE(PVC.DownVotes, 0)) DESC) AS VoteRank
    FROM Posts P
    LEFT JOIN PostVoteCounts PVC ON P.Id = PVC.PostId
    WHERE P.PostTypeId = 1 AND P.Score > 0
),
UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        AB.GoldBadges,
        AB.SilverBadges,
        AB.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY UR.Reputation DESC) AS UserRank
    FROM UserReputation UR
    LEFT JOIN UserBadges AB ON UR.UserId = AB.UserId
)

SELECT 
    PU.UserId,
    U.DisplayName,
    PU.Reputation,
    PU.GoldBadges,
    PU.SilverBadges,
    PU.BronzeBadges,
    PT.PostId,
    PT.Title,
    PT.CreationDate,
    PT.NetVotes
FROM TopPosts PT
JOIN TopUsers PU ON PT.VoteRank = PU.UserRank
JOIN Users U ON PU.UserId = U.Id
WHERE PU.UserRank <= 50
ORDER BY PT.NetVotes DESC, PU.Reputation DESC;
