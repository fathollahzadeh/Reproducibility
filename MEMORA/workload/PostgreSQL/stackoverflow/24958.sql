WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(C.ID), 0) AS CommentCount,
        COALESCE(PH.Comment, 'No history') AS LastCloseReason,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON PH.PostId = P.Id AND PH.PostHistoryTypeId = 10
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId, P.CreationDate, P.Score, PH.Comment
),
ActiveUserPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        US.DisplayName,
        US.Reputation,
        US.TotalBountyAmount,
        PS.CommentCount,
        PS.LastCloseReason,
        US.GoldBadges,
        US.SilverBadges,
        US.BronzeBadges,
        CASE 
            WHEN PS.CommentCount > 5 THEN 'High Engagement'
            WHEN PS.CommentCount BETWEEN 1 AND 5 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        PostStatistics PS
    JOIN 
        UserScores US ON PS.OwnerUserId = US.UserId
    WHERE 
        US.Reputation >= 100 AND
        (PS.CommentCount IS NULL OR PS.CommentCount >= 2)
),
FinalResults AS (
    SELECT 
        AUP.*,
        ROW_NUMBER() OVER (ORDER BY AUP.Reputation DESC, AUP.CommentCount DESC) AS Ranking
    FROM 
        ActiveUserPosts AUP
)
SELECT 
    *,
    CASE 
        WHEN LastCloseReason IS NOT NULL THEN CONCAT('Last closed reason: ', LastCloseReason)
        ELSE 'No closure activity'
    END AS ClosureStatus
FROM 
    FinalResults
ORDER BY 
    Ranking;