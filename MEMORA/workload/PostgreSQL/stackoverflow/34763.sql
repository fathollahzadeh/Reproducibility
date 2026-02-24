WITH RECURSIVE TopPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS rn
    FROM 
        Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
),
PostVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) AS CloseVoteCount
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostHistoryAggregate AS (
    SELECT 
        PH.PostId,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId IN (10, 11)) AS CloseActions,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 24) AS SuggestedEdits
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    TP.Id AS PostId,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.CreationDate,
    TP.OwnerDisplayName,
    COALESCE(PV.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(PV.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(PH.CloseActions, 0) AS CloseActions,
    COALESCE(PH.SuggestedEdits, 0) AS SuggestedEdits
FROM 
    TopPosts TP
LEFT JOIN 
    PostVotes PV ON TP.Id = PV.PostId
LEFT JOIN 
    PostHistoryAggregate PH ON TP.Id = PH.PostId
WHERE 
    TP.rn <= 10 
ORDER BY 
    TP.Score DESC, 
    TP.ViewCount DESC;