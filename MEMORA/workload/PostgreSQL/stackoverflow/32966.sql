
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostHistories AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    COALESCE(PV.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PV.DownVotes, 0) AS TotalDownVotes,
    COALESCE(PC.CommentCount, 0) AS TotalComments,
    COALESCE(PH.EditCount, 0) AS TotalEdits,
    CASE 
        WHEN RP.Score IS NULL OR RP.Score < 0 THEN 'No Score'
        WHEN RP.Score >= 0 AND RP.Score < 10 THEN 'Low Score'
        WHEN RP.Score >= 10 AND RP.Score <= 50 THEN 'Moderate Score'
        ELSE 'High Score'
    END AS ScoreCategory,
    RANK() OVER (ORDER BY RP.Score DESC, RP.ViewCount DESC) AS GlobalRank
FROM 
    RankedPosts RP
LEFT JOIN 
    PostVotes PV ON RP.PostId = PV.PostId
LEFT JOIN 
    PostComments PC ON RP.PostId = PC.PostId
LEFT JOIN 
    PostHistories PH ON RP.PostId = PH.PostId
WHERE 
    RP.PostRank = 1
ORDER BY 
    RP.CreationDate DESC;
