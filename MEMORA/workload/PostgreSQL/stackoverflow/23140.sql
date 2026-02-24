
WITH UserReputation AS (
    SELECT 
        U.Id,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedID, 
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        AVG(P.Score) OVER (PARTITION BY P.PostTypeId) AS AvgScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.CreationDate >= (DATE '2024-10-01' - INTERVAL '1 year')
    GROUP BY 
        P.Id, P.PostTypeId, P.AcceptedAnswerId
),
BadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostHistoryAggregated AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UR.Reputation, 0) AS Reputation,
    T.TotalComments,
    T.UpVotesCount,
    T.DownVotesCount,
    B.BadgeCount,
    B.GoldBadges,
    B.SilverBadges,
    B.BronzeBadges,
    PH.HistoryTypes,
    PH.HistoryCount,
    CASE 
        WHEN T.AvgScore IS NULL THEN 'No Score'
        WHEN T.AvgScore > 10 THEN 'High Score'
        ELSE 'Moderate Score'
    END AS PostScoreCategory
FROM 
    Users U
LEFT JOIN 
    UserReputation UR ON U.Id = UR.Id
LEFT JOIN 
    TopPosts T ON U.Id = T.PostId  
LEFT JOIN 
    BadgeSummary B ON U.Id = B.UserId
LEFT JOIN 
    PostHistoryAggregated PH ON T.PostId = PH.PostId
WHERE 
    U.Location IS NOT NULL
    AND TRIM(U.Location) <> ''
    AND COALESCE(B.BadgeCount, 0) >= 1
ORDER BY 
    UR.Reputation DESC, 
    T.TotalComments DESC 
LIMIT 100;
