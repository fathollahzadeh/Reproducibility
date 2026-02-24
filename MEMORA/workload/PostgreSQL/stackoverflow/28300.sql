
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
),
TopRankedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Tags,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 5 
),
PostStatistics AS (
    SELECT 
        TRP.Tags,
        COUNT(TRP.PostId) AS TotalPosts,
        AVG(TRP.ViewCount) AS AvgViews,
        SUM(TRP.Score) AS TotalScore
    FROM 
        TopRankedPosts TRP
    GROUP BY 
        TRP.Tags
),
PostDetail AS (
    SELECT 
        TRP.PostId,
        TRP.Title,
        TRP.OwnerDisplayName,
        TRP.CreationDate,
        PS.TotalPosts,
        PS.AvgViews,
        PS.TotalScore
    FROM 
        TopRankedPosts TRP
    JOIN 
        PostStatistics PS ON TRP.Tags = PS.Tags
)
SELECT 
    PD.Title,
    PD.OwnerDisplayName,
    PD.CreationDate,
    PD.TotalPosts,
    PD.AvgViews,
    PD.TotalScore,
    STRING_AGG(PT.Name, ', ') AS PostTypes
FROM 
    PostDetail PD
LEFT JOIN 
    PostTypes PT ON PT.Id = (SELECT PostTypeId FROM Posts WHERE Id = PD.PostId LIMIT 1)
GROUP BY 
    PD.Title, PD.OwnerDisplayName, PD.CreationDate, PD.TotalPosts, PD.AvgViews, PD.TotalScore
ORDER BY 
    PD.TotalScore DESC;
