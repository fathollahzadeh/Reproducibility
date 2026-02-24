WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
        AND P.Score > 0 
),
TopTags AS (
    SELECT 
        Tags,
        COUNT(*) AS QuestionCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
    GROUP BY 
        Tags
    HAVING 
        COUNT(*) > 1 
),
MostPopularTags AS (
    SELECT 
        Tags
    FROM 
        TopTags
    ORDER BY 
        QuestionCount DESC 
    LIMIT 10 
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.Score,
    RP.OwnerName,
    MPT.Tags
FROM 
    RankedPosts RP
JOIN 
    MostPopularTags MPT ON RP.Tags LIKE CONCAT('%', MPT.Tags, '%')
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Tags, RP.Score DESC;