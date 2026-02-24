WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        P.AnswerCount,
        ROW_NUMBER() OVER(PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
HighScoringPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.AnswerCount
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 5
),
PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        SUM(CASE WHEN PHT.Name = 'Edit Body' THEN 1 ELSE 0 END) AS BodyEdits,
        SUM(CASE WHEN PHT.Name = 'Edit Title' THEN 1 ELSE 0 END) AS TitleEdits
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
AggregateVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes V
    JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        V.PostId
)
SELECT 
    HSP.PostId,
    HSP.Title,
    HSP.OwnerDisplayName,
    HSP.CreationDate,
    HSP.Score,
    HSP.ViewCount,
    HSP.AnswerCount,
    COALESCE(PHC.EditCount, 0) AS EditCount,
    COALESCE(PHC.BodyEdits, 0) AS BodyEdits,
    COALESCE(PHC.TitleEdits, 0) AS TitleEdits,
    COALESCE(AV.Upvotes, 0) AS Upvotes,
    COALESCE(AV.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN COALESCE(AV.Upvotes, 0) > COALESCE(AV.Downvotes, 0) THEN 'Positive'
        WHEN COALESCE(AV.Upvotes, 0) < COALESCE(AV.Downvotes, 0) THEN 'Negative'
        ELSE 'Neutral' 
    END AS VoteSentiment
FROM 
    HighScoringPosts HSP
LEFT JOIN 
    PostHistoryCounts PHC ON HSP.PostId = PHC.PostId
LEFT JOIN 
    AggregateVotes AV ON HSP.PostId = AV.PostId
ORDER BY 
    HSP.Score DESC, HSP.CreationDate DESC;