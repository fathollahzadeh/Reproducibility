WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, Reputation, PostCount, TotalViews, TotalScore
    FROM 
        UserStats
    WHERE 
        Rank <= 10
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        V.UserId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.TotalViews,
    T.TotalScore,
    COALESCE(R.VoteCount, 0) AS RecentVoteCount,
    COALESCE(R.UpVotes, 0) AS RecentUpVotes,
    COALESCE(R.DownVotes, 0) AS RecentDownVotes,
    COALESCE(B.GoldBadges, 0) AS GoldBadges,
    COALESCE(B.SilverBadges, 0) AS SilverBadges,
    COALESCE(B.BronzeBadges, 0) AS BronzeBadges
FROM 
    TopUsers T
LEFT JOIN 
    RecentVotes R ON T.UserId = R.UserId
LEFT JOIN 
    UserBadges B ON T.UserId = B.UserId
ORDER BY 
    T.TotalScore DESC, T.Reputation DESC;