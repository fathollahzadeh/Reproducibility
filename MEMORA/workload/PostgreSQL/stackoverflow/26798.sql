
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagList
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(P.Tags, '><')) AS T(TagName) ON TRUE
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, P.OwnerUserId, P.Score, P.ViewCount
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        P.Title,
        P.Body
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10
),
RankedPosts AS (
    SELECT 
        PM.*,
        ROW_NUMBER() OVER (ORDER BY PM.Score DESC, PM.ViewCount DESC, PM.CommentCount DESC) AS Ranking
    FROM 
        PostMetrics PM
)
SELECT 
    RP.Ranking,
    RP.Title,
    RP.PostId,
    RP.Body,
    RP.TagList,
    U.DisplayName AS OwnerDisplayName,
    UBad.BadgeCount,
    UBad.BadgeNames,
    CP.ClosedDate
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges UBad ON U.Id = UBad.UserId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.Ranking <= 10 
ORDER BY 
    RP.Ranking;
