
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS Author,
        U.Reputation AS AuthorReputation,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS TagRank,
        ARRAY_AGG(DISTINCT T.TagName) AS TagList
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS T(TagName) ON true
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName, U.Reputation, P.ViewCount, P.Score, P.Tags
),

MostVotedTags AS (
    SELECT 
        TagList,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts
    WHERE 
        TagRank = 1
    GROUP BY 
        TagList
    HAVING 
        COUNT(*) > 5 
),

FinalOutput AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Author,
        RP.AuthorReputation,
        RP.ViewCount,
        RP.Score,
        MT.TagList,
        RANK() OVER (ORDER BY RP.Score DESC) AS PostRank
    FROM 
        RankedPosts RP
    JOIN 
        MostVotedTags MT ON MT.TagList @> RP.TagList
)

SELECT 
    FO.PostId,
    FO.Title,
    FO.Author,
    FO.AuthorReputation,
    FO.ViewCount,
    FO.Score,
    FO.TagList,
    FO.PostRank
FROM 
    FinalOutput FO
WHERE 
    FO.PostRank <= 10 
ORDER BY 
    FO.Score DESC, 
    FO.ViewCount DESC;
