
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
), 
UserVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
), 
PostHistory AS (
    SELECT 
        PH.PostId,
        ARRAY_AGG(PH.Comment) AS HistoryComments,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        PH.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.ViewCount,
    TP.Score,
    TP.OwnerDisplayName,
    COALESCE(UV.UpVotes, 0) AS UpVotes,
    COALESCE(UV.DownVotes, 0) AS DownVotes,
    COALESCE(PH.HistoryComments, ARRAY[]::TEXT[]) AS HistoryComments,
    COALESCE(PH.EditCount, 0) AS EditCount
FROM 
    TopPosts TP
LEFT JOIN 
    UserVotes UV ON TP.PostId = UV.PostId
LEFT JOIN 
    PostHistory PH ON TP.PostId = PH.PostId
WHERE 
    TP.Score >= 10
ORDER BY 
    TP.ViewCount DESC, TP.Score DESC;
