WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.PostTypeId = 1 
),
RecentBadges AS (
    SELECT
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM
        Badges B
    WHERE
        B.Date >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY
        B.UserId
),
ClosedPosts AS (
    SELECT
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        PH.Comment
    FROM
        PostHistory PH
    WHERE
        PH.PostHistoryTypeId = 10 
),
ActiveUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        LastAccessDate
    FROM 
        Users
    WHERE 
        LastAccessDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
AggregateVotes AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM
        Votes
    GROUP BY 
        PostId
)
SELECT
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    RB.BadgeCount,
    RB.BadgeNames,
    COALESCE(AP.Upvotes, 0) AS Upvotes,
    COALESCE(AP.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN CP.PostId IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = RP.PostId) AS CommentCount
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentBadges RB ON RP.OwnerUserId = RB.UserId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
LEFT JOIN 
    AggregateVotes AP ON RP.PostId = AP.PostId
WHERE 
    RP.PostRank = 1 
ORDER BY 
    RP.CreationDate DESC
LIMIT 50;