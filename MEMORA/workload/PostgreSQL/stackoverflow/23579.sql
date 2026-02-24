WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostsCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
BadgesByType AS (
    SELECT 
        U.Id AS UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldCount, 
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        PH.UserId, PH.PostId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.UpvoteCount,
    US.DownvoteCount,
    US.PostsCount,
    US.TotalViews,
    B.BadgeNames,
    B.GoldCount,
    B.SilverCount,
    B.BronzeCount,
    PHS.HistoryTypes,
    PHS.HistoryCount,
    CASE 
        WHEN US.UpvoteCount > US.DownvoteCount THEN 'Positive'
        WHEN US.UpvoteCount < US.DownvoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    UserStats US
LEFT JOIN 
    BadgesByType B ON US.UserId = B.UserId
LEFT JOIN 
    PostHistorySummary PHS ON US.UserId = PHS.UserId
WHERE 
    US.PostsCount > 0
ORDER BY 
    US.Rank;