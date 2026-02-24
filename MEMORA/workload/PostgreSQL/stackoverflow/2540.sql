WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER(PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER(PARTITION BY P.Id) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER(PARTITION BY P.Id) AS DownvoteCount,
        COALESCE(PH.Comment, 'No close reason provided') AS CloseReason
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.RankByScore,
        RP.UpvoteCount,
        RP.DownvoteCount,
        CASE 
            WHEN RP.UpvoteCount IS NULL THEN 'None'
            WHEN RP.UpvoteCount - RP.DownvoteCount >= 0 THEN 'Positive'
            ELSE 'Negative'
        END AS VoteSentiment
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankByScore <= 10
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.CreationDate,
    FP.Score,
    FP.ViewCount,
    FP.VoteSentiment,
    SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    FilteredPosts FP
LEFT JOIN 
    Badges B ON FP.PostId = B.UserId
GROUP BY 
    FP.PostId, FP.Title, FP.CreationDate, FP.Score, FP.ViewCount, FP.VoteSentiment
ORDER BY 
    FP.Score DESC, FP.CreationDate DESC;