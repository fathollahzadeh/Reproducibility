
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostsWithVotes AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(PWV.VoteCount, 0) AS TotalVotes,
    COALESCE(PWV.UpVotes, 0) AS UpVotes,
    COALESCE(PWV.DownVotes, 0) AS DownVotes,
    UPS.TotalPosts,
    UPS.TotalViews,
    UPS.AverageScore,
    UPS.LastPostDate,
    CASE 
        WHEN UPS.LastPostDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS UserActivityStatus,
    CASE 
        WHEN COALESCE(UPS.TotalPosts, 0) > 10 AND COALESCE(UB.BadgeCount, 0) >= 5 THEN 'Veteran Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostsWithVotes PWV ON U.Id = PWV.OwnerUserId
LEFT JOIN 
    UserPostStats UPS ON U.Id = UPS.UserId
ORDER BY 
    TotalVotes DESC, TotalBadges DESC
LIMIT 50;
