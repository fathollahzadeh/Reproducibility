
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts,
        SUM(CASE WHEN P.LastActivityDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentActivity
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName
), RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        V.UserId
), BadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.Questions,
    UA.Answers,
    UA.ClosedPosts,
    UA.RecentActivity,
    COALESCE(RV.TotalVotes, 0) AS TotalVotes,
    COALESCE(RV.UpVotes, 0) AS UpVotes,
    COALESCE(RV.DownVotes, 0) AS DownVotes,
    COALESCE(BS.TotalBadges, 0) AS TotalBadges,
    COALESCE(BS.GoldBadges, 0) AS GoldBadges,
    COALESCE(BS.SilverBadges, 0) AS SilverBadges,
    COALESCE(BS.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserActivity UA
LEFT JOIN 
    RecentVotes RV ON UA.UserId = RV.UserId
LEFT JOIN 
    BadgeSummary BS ON UA.UserId = BS.UserId
ORDER BY 
    UA.TotalPosts DESC
LIMIT 100;
