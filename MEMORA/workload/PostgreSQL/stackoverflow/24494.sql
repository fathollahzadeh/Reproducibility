WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS Upvotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS Downvotes,
        COUNT(V.Id) AS TotalVotes,
        AVG(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpvote,
        AVG(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AvgDownvote
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),

ClosedPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS ClosedPosts,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedByUser,
        SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedByUser
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON PH.PostId = P.Id 
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        P.OwnerUserId
),

UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),

FinalStats AS (
    SELECT 
        UV.UserId,
        UV.DisplayName,
        COALESCE(CPS.ClosedPosts, 0) AS ClosedPosts,
        COALESCE(CPS.ClosedByUser, 0) AS ClosedByUser,
        COALESCE(CPS.ReopenedByUser, 0) AS ReopenedByUser,
        COALESCE(UBS.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBS.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBS.BronzeBadges, 0) AS BronzeBadges,
        UV.Upvotes,
        UV.Downvotes,
        UV.TotalVotes,
        UV.AvgUpvote,
        UV.AvgDownvote
    FROM 
        UserVoteStats UV
    LEFT JOIN 
        ClosedPostStats CPS ON UV.UserId = CPS.OwnerUserId
    LEFT JOIN 
        UserBadgeStats UBS ON UV.UserId = UBS.UserId
)

SELECT 
    *,
    CASE 
        WHEN ClosedPosts > 0 THEN 'Active Participant'
        ELSE 'Newcomer'
    END AS UserCategory,
    CASE 
        WHEN GoldBadges >= 3 THEN 'Super User'
        WHEN SilverBadges >= 5 THEN 'Contributing Member'
        ELSE 'Member'
    END AS BadgeCategory,
    (CASE WHEN TotalVotes > 0 
          THEN CAST(Upvotes AS FLOAT) / TotalVotes 
          ELSE NULL 
     END) AS UpvoteRatio,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM Tags T 
     JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
     WHERE P.OwnerUserId = FinalStats.UserId) AS AssociatedTags
FROM 
    FinalStats 
WHERE 
    Upvotes > Downvotes
ORDER BY 
    UpvoteRatio DESC NULLS LAST, 
    DisplayName ASC;
