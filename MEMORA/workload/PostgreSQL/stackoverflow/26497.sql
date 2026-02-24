
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
RecentPostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        P.Body
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
TaggedPostStatistics AS (
    SELECT 
        PT.TagName,
        COUNT(P.Id) AS PostCount,
        AVG(P.ViewCount) AS AverageViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    JOIN 
        LATERAL (SELECT unnest(string_to_array(P.Tags, ',')) AS tag) tag ON TRUE
    JOIN 
        Tags PT ON tag = PT.TagName
    GROUP BY 
        PT.TagName
    ORDER BY 
        PostCount DESC
),
UserEngagementStats AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesGiven,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesGiven,
        COUNT(C.Id) AS CommentsGiven
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    RPD.PostId,
    RPD.Title,
    RPD.CreationDate AS PostCreationDate,
    RPD.ViewCount,
    RPD.Score AS PostScore,
    UES.UpVotesGiven,
    UES.DownVotesGiven,
    UES.CommentsGiven,
    TPS.TagName,
    TPS.PostCount,
    TPS.AverageViews,
    TPS.AverageScore
FROM 
    UserBadges UB
JOIN 
    Users U ON UB.UserId = U.Id
LEFT JOIN 
    RecentPostDetails RPD ON U.DisplayName = RPD.OwnerDisplayName
LEFT JOIN 
    UserEngagementStats UES ON U.Id = UES.UserId
LEFT JOIN 
    (SELECT TagName, PostCount, AverageViews, AverageScore 
     FROM TaggedPostStatistics) TPS ON TRUE
ORDER BY 
    UB.BadgeCount DESC, RPD.ViewCount DESC, TPS.PostCount DESC;
