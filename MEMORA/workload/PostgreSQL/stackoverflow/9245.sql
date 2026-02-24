WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users AS U
    LEFT JOIN 
        Badges AS B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),

PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts AS P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),

VoteStats AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes AS V
    GROUP BY 
        V.UserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PS.PostCount, 0) AS PostCount,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    COALESCE(PS.AvgScore, 0) AS AvgScore,
    COALESCE(VS.VoteCount, 0) AS VoteCount,
    COALESCE(VS.UpVotes, 0) AS UpVotes,
    COALESCE(VS.DownVotes, 0) AS DownVotes
FROM 
    Users AS U
LEFT JOIN 
    UserBadges AS UB ON U.Id = UB.UserId
LEFT JOIN 
    PostStats AS PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    VoteStats AS VS ON U.Id = VS.UserId
ORDER BY 
    TotalScore DESC, 
    PostCount DESC, 
    BadgeCount DESC
LIMIT 100;