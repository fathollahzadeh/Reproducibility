
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        P.CreationDate,
        P.Body,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.PostId) OVER(PARTITION BY P.Id) AS TotalComments,
        RANK() OVER(PARTITION BY P.Tags ORDER BY P.Score DESC) AS RankWithinTag
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
),
FilteredRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        CreationDate,
        Body,
        OwnerDisplayName,
        TotalComments,
        RankWithinTag
    FROM 
        RankedPosts
    WHERE 
        TotalComments > 5 
)
SELECT 
    R.Tags,
    COUNT(R.PostId) AS PostCount,
    AVG(R.TotalComments) AS AvgComments,
    STRING_AGG(R.OwnerDisplayName, ', ') AS Owners,
    STRING_AGG(R.Title, '; ') AS Titles
FROM 
    FilteredRankedPosts R
GROUP BY 
    R.Tags
HAVING 
    COUNT(R.PostId) >= 3 
ORDER BY 
    PostCount DESC, 
    AvgComments DESC;
