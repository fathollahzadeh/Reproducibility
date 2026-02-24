WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.OwnerUserId, P.Score, P.Title, P.CreationDate
),
UsersWithBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeLevel
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
HighScoringPosts AS (
    SELECT 
        RP.PostId,
        RP.Score,
        RP.Title,
        UB.BadgeCount,
        UB.HighestBadgeLevel
    FROM 
        RankedPosts RP
    INNER JOIN 
        UsersWithBadges UB ON RP.OwnerUserId = UB.UserId
    WHERE 
        RP.Score > 100 AND RP.Rank <= 5
)
SELECT 
    HSP.PostId,
    HSP.Title,
    HSP.Score,
    HSP.BadgeCount,
    HSP.HighestBadgeLevel,
    COALESCE(HSP.BadgeCount, 0) AS BadgeCountPresent,
    CASE 
        WHEN HSP.HighestBadgeLevel IS NULL THEN 'No badges'
        ELSE 
            CASE 
                WHEN HSP.HighestBadgeLevel = 1 THEN 'Gold'
                WHEN HSP.HighestBadgeLevel = 2 THEN 'Silver'
                ELSE 'Bronze'
            END
    END AS HighestBadgeName,
    (SELECT 
        COUNT(*) 
     FROM 
        Comments C 
     WHERE 
        C.PostId = HSP.PostId) AS CommentCount,
    (SELECT 
        COUNT(*) 
     FROM 
        PostHistory PH 
     WHERE 
        PH.PostId = HSP.PostId 
        AND PH.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
    CASE 
        WHEN HSP.Score > (SELECT AVG(Score) FROM Posts) THEN 'Above Average'
        ELSE 'Below Average'
    END AS ScoreComparison
FROM 
    HighScoringPosts HSP
ORDER BY 
    HSP.Score DESC
LIMIT 10;