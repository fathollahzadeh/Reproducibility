
WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY P.Id, P.OwnerUserId
),
AggregateUserPostData AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(RPA.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(RPA.UpvoteCount - RPA.DownvoteCount), 0) AS NetVotes,
        MAX(RPA.RecentPostRank) AS RecentPostRank
    FROM Users U
    LEFT JOIN RecentPostActivity RPA ON U.Id = RPA.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.Reputation,
    A.TotalComments,
    A.NetVotes,
    CASE 
        WHEN A.Reputation >= 1000 THEN 'Expert'
        WHEN A.Reputation >= 500 THEN 'Contributor'
        WHEN A.Reputation >= 100 THEN 'Novice'
        ELSE 'Newbie'
    END AS UserLevel,
    UB.BadgeCount
FROM AggregateUserPostData A
JOIN UserBadges UB ON A.UserId = UB.UserId
WHERE A.RecentPostRank IS NOT NULL
ORDER BY A.Reputation DESC, A.TotalComments DESC
LIMIT 10;
