
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankByScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 10 THEN 1 END) AS CloseVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId, U.DisplayName
),

PopularTags AS (
    SELECT 
        Tags,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tags
    HAVING 
        COUNT(*) > 10 
),

TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        SUM(P.Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(P.Score) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    RP.UpVotes,
    RP.DownVotes,
    RP.CloseVotes,
    T.TagCount,
    TU.UserRank
FROM 
    RankedPosts RP
LEFT JOIN 
    PopularTags T ON RP.Title LIKE '%' || T.Tags || '%'
LEFT JOIN 
    TopUsers TU ON RP.OwnerUserId = TU.Id
WHERE 
    RP.RankByScore <= 3 
    AND (RP.CloseVotes = 0 OR RP.CloseVotes IS NULL) 
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;
