
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(U.DisplayName, 'Anonymous') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostAnalytics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerUserId,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.AnswerCount,
        COALESCE(UR.Reputation, 0) AS UserReputation,
        COALESCE(UR.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(UR.LastBadgeDate, CAST('1970-01-01' AS TIMESTAMP)) AS LastBadgeDate,
        CASE 
            WHEN RP.AnswerCount > 0 THEN 
                ROUND((CAST(RP.Score AS DECIMAL) / NULLIF(RP.AnswerCount, 0)), 2) 
            ELSE 0 
        END AS ScorePerAnswer
    FROM 
        RecentPosts RP
    LEFT JOIN 
        UserReputation UR ON RP.OwnerUserId = UR.UserId
)
SELECT 
    PA.PostId,
    PA.Title,
    PA.OwnerDisplayName,
    PA.CreationDate,
    PA.Score,
    PA.ViewCount,
    PA.AnswerCount,
    PA.UserReputation,
    PA.UserBadgeCount,
    PA.ScorePerAnswer,
    COUNT(PH.Id) AS EditHistoryCount,
    STRING_AGG(DISTINCT CONCAT(PH.Comment, ' (', PH.CreationDate, ')'), '; ') AS EditHistoryComments
FROM 
    PostAnalytics PA
LEFT JOIN 
    PostHistory PH ON PA.PostId = PH.PostId 
    AND PH.PostHistoryTypeId IN (4, 5, 6) 
GROUP BY 
    PA.PostId, PA.Title, PA.OwnerDisplayName, PA.CreationDate, PA.Score, PA.ViewCount, PA.AnswerCount, PA.UserReputation, PA.UserBadgeCount, PA.ScorePerAnswer
HAVING 
    PA.ScorePerAnswer > 1 OR PA.UserReputation > 1000
ORDER BY 
    PA.Score DESC, PA.CreationDate ASC
LIMIT 50;
