
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        DENSE_RANK() OVER (ORDER BY SUM(U.UpVotes) - SUM(U.DownVotes) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        P.CreationDate,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY P.Id
),
PostTypeCounts AS (
    SELECT 
        P.PostTypeId,
        COUNT(*) AS PostCount
    FROM Posts P
    GROUP BY P.PostTypeId
),
RankedPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.OwnerUserId,
        PD.AcceptedAnswerId,
        PD.CreationDate,
        PD.ViewCount,
        PD.CommentCount,
        RANK() OVER (PARTITION BY PD.OwnerUserId ORDER BY PD.ViewCount DESC) AS ViewRank
    FROM PostDetails PD
)
SELECT 
    UB.UserId,
    U.DisplayName,
    U.Reputation,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PP.Title AS TopPostTitle,
    PP.ViewCount AS MaxViewCount,
    PT.PostCount AS TotalPosts,
    COALESCE(PA.Title, '(No Accepted Answer)') AS AcceptedAnswerTitle,
    PA.CreationDate AS AcceptedAnswerDate
FROM UserBadges UB
JOIN Users U ON UB.UserId = U.Id
LEFT JOIN RankedPosts PP ON PP.OwnerUserId = U.Id AND PP.ViewRank = 1
LEFT JOIN Posts PA ON PA.Id = PP.AcceptedAnswerId
LEFT JOIN PostTypeCounts PT ON PT.PostTypeId IN (1, 2)
WHERE U.Reputation > 500
ORDER BY U.Reputation DESC, UB.UserRank;
