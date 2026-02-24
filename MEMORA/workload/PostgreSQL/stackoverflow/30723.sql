
WITH RecursivePostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS UserRank,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE
        P.PostTypeId = 1  
),
UserBadgesCTE AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostVotesAggregated AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
ModifiedPosts AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId IN (4, 5) THEN PH.CreationDate END) AS LastModifiedDate,
        STRING_AGG(PH.UserDisplayName, ', ') AS Editors
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.AnswerCount,
    RP.Score,
    U.BadgeCount,
    U.BadgeNames,
    COALESCE(PVA.Upvotes, 0) AS Upvotes,
    COALESCE(PVA.Downvotes, 0) AS Downvotes,
    COALESCE(PVA.TotalVotes, 0) AS TotalVotes,
    MP.LastModifiedDate,
    MP.Editors
FROM 
    RecursivePostCTE RP
LEFT JOIN 
    UserBadgesCTE U ON RP.UserRank = 1 AND U.UserId = RP.OwnerUserId
LEFT JOIN 
    PostVotesAggregated PVA ON RP.PostId = PVA.PostId
LEFT JOIN 
    ModifiedPosts MP ON RP.PostId = MP.PostId
WHERE 
    RP.Score > 10
    AND RP.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
ORDER BY 
    RP.Score DESC,
    RP.ViewCount DESC;
