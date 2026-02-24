WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation >= 1000
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Tags T ON POSITION(T.TagName IN P.Tags) > 0
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        P.Id,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        P.CommentCount
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.OwnerUserId,
        RU.DisplayName AS OwnerDisplayName,
        RP.Score,
        RP.ViewCount,
        RP.CommentCount,
        RP.Tags,
        COALESCE(AVG(C.Score), 0) AS AverageCommentScore,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT PH.Id) AS EditCount
    FROM 
        RecentPosts RP
    LEFT JOIN 
        Comments C ON C.PostId = RP.PostId
    LEFT JOIN 
        PostHistory PH ON PH.PostId = RP.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)
    LEFT JOIN 
        RankedUsers RU ON RP.OwnerUserId = RU.Id
    GROUP BY 
        RP.PostId, RP.Title, RP.CreationDate, RP.OwnerUserId, RU.DisplayName, RP.Score, RP.ViewCount, RP.CommentCount, RP.Tags
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.OwnerDisplayName,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.Tags,
    PS.AverageCommentScore,
    PS.TotalComments,
    PS.EditCount
FROM 
    PostStatistics PS
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC, PS.TotalComments DESC;