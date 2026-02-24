
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND P.Score > 10
), 
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopPostComments AS (
    SELECT 
        C.PostId,
        COUNT(*) AS CommentCount,
        AVG(LENGTH(C.Text)) AS AvgCommentLength
    FROM 
        Comments C
    GROUP BY 
        C.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    US.DisplayName AS Author,
    US.TotalPosts,
    US.TotalBounties,
    COALESCE(TPC.CommentCount, 0) AS CommentCount,
    COALESCE(TPC.AvgCommentLength, 0) AS AvgCommentLength
FROM 
    RankedPosts RP
LEFT JOIN 
    UserStatistics US ON RP.PostId = US.UserId
LEFT JOIN 
    TopPostComments TPC ON RP.PostId = TPC.PostId
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC;
