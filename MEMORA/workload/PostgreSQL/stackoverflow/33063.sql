WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  
        AND P.Score > 0   
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags ILIKE CONCAT('%', T.TagName, '%')
    WHERE 
        P.PostTypeId = 1  
        AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        T.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        COUNT(CM.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title
),
FinalResults AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.LastActivityDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        PA.UpVotes,
        PA.DownVotes,
        PA.CloseCount,
        PA.CommentCount,
        RANK() OVER (ORDER BY PA.UpVotes DESC, PA.CommentCount DESC) AS PopularityRank,
        (SELECT STRING_AGG(TagName, ', ') FROM PopularTags) AS TopTags
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostAnalytics PA ON RP.PostId = PA.PostId
)

SELECT * 
FROM FinalResults 
WHERE 
    PopularityRank <= 10
ORDER BY 
    PopularityRank;