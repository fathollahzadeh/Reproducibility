WITH UserActivities AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUserActivities AS (
    SELECT 
        UserId, DisplayName, PostCount, TotalViewCount, UpVotes, DownVotes
    FROM 
        UserActivities
    WHERE 
        ActivityRank <= 10
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS Gold,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS Silver,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS Bronze
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    TUA.DisplayName,
    TUA.PostCount,
    TUA.TotalViewCount,
    COALESCE(UB.Gold, 0) AS GoldBadges,
    COALESCE(UB.Silver, 0) AS SilverBadges,
    COALESCE(UB.Bronze, 0) AS BronzeBadges,
    CASE 
        WHEN (TUA.TotalViewCount > 1000 AND TUA.PostCount > 20) THEN 'High Contributor'
        WHEN (TUA.TotalViewCount <= 1000 AND TUA.PostCount <= 20) THEN 'Low Contributor'
        ELSE 'Moderate Contributor'
    END AS ContributionLevel,
    CASE 
        WHEN TUA.TotalViewCount IS NULL THEN 'Views Not Recorded'
        ELSE 'Views Recorded'
    END AS ViewStatus
FROM 
    TopUserActivities TUA
LEFT JOIN 
    UserBadges UB ON TUA.UserId = UB.UserId
ORDER BY 
    TUA.TotalViewCount DESC, TUA.PostCount DESC;