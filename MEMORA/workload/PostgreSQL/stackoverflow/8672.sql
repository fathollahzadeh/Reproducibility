WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        P.ViewCount, 
        U.DisplayName AS OwnerDisplayName, 
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoteDetails AS (
    SELECT 
        V.PostId, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostHistorySummary AS (
    SELECT 
        PH.PostId, 
        COUNT(PH.Id) AS EditCount, 
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
TopPosts AS (
    SELECT 
        RP.PostId, 
        RP.Title, 
        RP.OwnerDisplayName, 
        RP.CreationDate, 
        RP.Score, 
        RP.ViewCount, 
        PVD.UpVotes,
        PVD.DownVotes,
        PHS.EditCount, 
        PHS.LastEditDate
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostVoteDetails PVD ON RP.PostId = PVD.PostId
    LEFT JOIN 
        PostHistorySummary PHS ON RP.PostId = PHS.PostId
    WHERE 
        RP.PostRank <= 10
)
SELECT 
    T.Id AS TagId, 
    T.TagName, 
    TP.* 
FROM 
    Tags T
JOIN 
    Posts P ON P.Tags LIKE '%' || T.TagName || '%'
JOIN 
    TopPosts TP ON P.Id = TP.PostId
ORDER BY 
    T.TagName, 
    TP.Score DESC;