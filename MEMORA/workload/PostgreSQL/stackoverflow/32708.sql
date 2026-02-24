WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
AcceptedAnswers AS (
    SELECT 
        P.Id AS AnswerId,
        P.AcceptedAnswerId,
        COUNT(COALESCE(V.Id, 0)) AS UpVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2 
    WHERE 
        P.PostTypeId = 2 
    GROUP BY 
        P.Id, P.AcceptedAnswerId
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(*) AS PostCount,
        SUM(COALESCE(CASE WHEN P.ViewCount IS NULL THEN 0 ELSE P.ViewCount END, 0)) AS TotalViews
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    AA.UpVoteCount,
    TS.PostCount AS TagPostCount,
    TS.TotalViews AS TagTotalViews,
    RPH.UserDisplayName AS RecentEditor,
    RPH.CreationDate AS RecentEditDate
FROM 
    RankedPosts RP
LEFT JOIN 
    AcceptedAnswers AA ON RP.PostId = AA.AcceptedAnswerId
LEFT JOIN 
    TagStats TS ON RP.Title LIKE '%' || TS.TagName || '%'
LEFT JOIN 
    RecentPostHistory RPH ON RP.PostId = RPH.PostId AND RPH.HistoryRank = 1
WHERE 
    RP.RN <= 5
ORDER BY 
    RP.CreationDate DESC;