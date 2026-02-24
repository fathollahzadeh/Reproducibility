
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostsWithBestAnswer AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(V.VoteCount, 0) AS VoteCount,
        P.AcceptedAnswerId,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN (SELECT COUNT(*) FROM Votes WHERE PostId = P.AcceptedAnswerId AND VoteTypeId = 2)
            ELSE 0
        END AS AcceptedAnswerVoteCount
    FROM Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM Votes 
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
)
SELECT 
    Ub.DisplayName AS UserDisplayName,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    COALESCE(P.AcceptedAnswerVoteCount, 0) AS AcceptedAnswerVotes,
    Ub.GoldBadges,
    Ub.SilverBadges,
    Ub.BronzeBadges,
    T.UserId AS TopUserId,
    T.DisplayName AS TopUserDisplayName,
    T.Rank AS UserRank
FROM UserBadges Ub
FULL OUTER JOIN PostsWithBestAnswer P ON Ub.UserId = P.AcceptedAnswerId
JOIN TopUsers T ON Ub.UserId = T.UserId
WHERE (Ub.BadgeCount > 0 OR P.AcceptedAnswerVoteCount > 0)
  AND T.Rank <= 10
ORDER BY T.Rank, P.CreationDate DESC;
