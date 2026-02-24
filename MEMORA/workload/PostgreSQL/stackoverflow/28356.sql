
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        U.DisplayName AS Author,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id AND V.VoteTypeId = 2 
    JOIN 
        Users U ON U.Id = P.OwnerUserId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Tags, U.DisplayName, P.CreationDate, P.PostTypeId
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        Author,
        CommentCount,
        VoteCount,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
DailyTrendingTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        CAST(P.CreationDate AS DATE) AS PostDate
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY 
        T.TagName, CAST(P.CreationDate AS DATE)
),
TrendingTags AS (
    SELECT 
        TagName,
        SUM(PostCount) AS TotalPosts
    FROM 
        DailyTrendingTags
    GROUP BY 
        TagName
    ORDER BY 
        TotalPosts DESC
    LIMIT 5
)
SELECT 
    TR.PostId,
    TR.Title,
    TR.Author,
    TR.CommentCount,
    TR.VoteCount,
    TR.CreationDate,
    TT.TagName
FROM 
    TopRankedPosts TR
LEFT JOIN 
    TrendingTags TT ON TR.Tags LIKE '%' || TT.TagName || '%'
ORDER BY 
    TR.CreationDate DESC;
