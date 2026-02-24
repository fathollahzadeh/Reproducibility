WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.PostTypeId = 1 
),
RecentPostHistory AS (
    SELECT
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate AS HistoryCreationDate,
        PH.UserDisplayName,
        P.Title
    FROM
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopTags AS (
    SELECT
        T.TagName,
        COUNT(T.Count) AS TotalPosts
    FROM
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(T.Count) > 10
),
VoteCounts AS (
    SELECT
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM
        Votes V
    GROUP BY 
        PostId
)
SELECT
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    COALESCE(V.UpVoteCount, 0) AS UpVotes,
    COALESCE(V.DownVoteCount, 0) AS DownVotes,
    TH.PostHistoryTypeId,
    TH.HistoryCreationDate,
    TH.UserDisplayName AS HistoryEditor,
    TT.TagName,
    TT.TotalPosts
FROM
    RankedPosts RP
LEFT JOIN 
    VoteCounts V ON RP.PostId = V.PostId
LEFT JOIN 
    RecentPostHistory TH ON RP.PostId = TH.PostId
LEFT JOIN 
    TopTags TT ON RP.Title LIKE '%' || TT.TagName || '%' 
WHERE
    RP.rn = 1 
ORDER BY 
    RP.CreationDate DESC, RP.Score DESC;