WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS Author,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS UpVoteCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagList
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2  
    LEFT JOIN 
        Tags T ON POSITION(T.TagName IN P.Tags) > 0   
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, U.DisplayName
),
PostBenchmarks AS (
    SELECT 
        RP.*,
        CASE
            WHEN RP.ViewCount >= 1000 THEN 'High'
            WHEN RP.ViewCount >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS Popularity,
        CASE
            WHEN RP.Score >= 50 THEN 'Expert'
            WHEN RP.Score >= 20 THEN 'Intermediate'
            ELSE 'Novice'
        END AS ExpertiseLevel
    FROM 
        RankedPosts RP
),
FinalOutput AS (
    SELECT 
        PB.PostId,
        PB.Title,
        PB.Author,
        PB.CreationDate,
        PB.ViewCount,
        PB.UpVoteCount,
        PB.CommentCount,
        PB.TagList,
        PB.Popularity,
        PB.ExpertiseLevel
    FROM 
        PostBenchmarks PB
    ORDER BY 
        PB.ViewCount DESC, PB.Score DESC
    LIMIT 100  
)
SELECT 
    *,
    (SELECT COUNT(*) FROM Posts WHERE CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year') AS TotalPostsLastYear
FROM 
    FinalOutput;