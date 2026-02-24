WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC NULLS LAST) AS PostRank,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS NewestPost
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND P.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(CAST(PH.Comment AS VARCHAR), '; ') AS CloseComments
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.CreationDate,
    RP.PostRank,
    CP.CloseCount,
    COALESCE(CP.CloseComments, 'No closure comments found') AS ClosureComments,
    US.DisplayName,
    US.TotalUpvotes,
    US.TotalDownvotes,
    US.BadgeCount,
    CASE 
        WHEN RP.NewestPost = 1 THEN 'Newest Post of Type' 
        ELSE 'Older Post'
    END AS PostStatus,
    CASE 
        WHEN RP.PostRank <= 5 THEN 'Top Ranked'
        WHEN RP.PostRank IS NULL THEN 'No Rank'
        ELSE 'Other Ranked Posts'
    END AS PopularityStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
LEFT JOIN 
    UserStats US ON RP.PostId = US.UserId
WHERE 
    RP.PostRank IS NOT NULL
    AND (RP.ViewCount > 100 OR US.TotalUpvotes > 10)
ORDER BY 
    RP.PostRank, RP.Title DESC NULLS LAST
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;