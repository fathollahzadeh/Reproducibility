WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(B.GoldBadges, 0) + COALESCE(B.SilverBadges, 0) + COALESCE(B.BronzeBadges, 0) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        UserBadges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > (SELECT AVG(Reputation) FROM Users)  
),
PostVoteSummary AS (
    SELECT 
        P.Id,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalBadges,
    P.Title,
    P.CreationDate,
    COALESCE(S.UpVotes, 0) AS TotalUpVotes,
    COALESCE(S.DownVotes, 0) AS TotalDownVotes,
    R.GoldBadges,
    R.SilverBadges,
    R.BronzeBadges,
    CASE 
        WHEN R.GoldBadges > 0 THEN 'Gold Member'
        WHEN R.SilverBadges > 0 THEN 'Silver Member'
        ELSE 'Regular Member'
    END AS MembershipStatus
FROM 
    TopUsers U
LEFT JOIN 
    UserBadges R ON U.Id = R.UserId
LEFT JOIN 
    RecentPosts P ON U.Id = P.OwnerUserId AND P.PostRank = 1
LEFT JOIN 
    PostVoteSummary S ON P.PostId = S.Id
WHERE 
    (U.Reputation BETWEEN 100 AND 1000 OR U.TotalBadges > 5)  
ORDER BY 
    U.Reputation DESC, 
    TotalUpVotes DESC
LIMIT 100;