WITH PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PH.UserId) AS UniqueEditors,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.CreationDate, P.PostTypeId
),
PostRecommendations AS (
    SELECT 
        P.Id as PostId,
        P.Title,
        COALESCE(T.TagName, 'Unlabeled') AS TagName,
        RANK() OVER (PARTITION BY P.Title ORDER BY P.ViewCount DESC) AS TagRank
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON POSITION(',' || T.TagName || ',' IN ',' || P.Tags || ',') > 0
    WHERE 
        P.ViewCount IS NOT NULL
),
UniqueEditorStats AS (
    SELECT 
        PostId,
        UniqueEditors,
        CASE 
            WHEN UniqueEditors > 10 THEN 'Highly Collaborative'
            WHEN UniqueEditors BETWEEN 5 AND 10 THEN 'Moderately Collaborative'
            ELSE 'Low Collaboration'
        END AS CollaborationLevel
    FROM 
        PostAnalytics
)

SELECT 
    PA.PostId,
    PA.Title,
    PA.OwnerDisplayName,
    PA.CommentCount,
    PA.UpVoteCount,
    PA.DownVoteCount,
    PA.CloseReopenCount,
    PA.CreationDate,
    PA.PostRank,
    COALESCE(PR.TagName, 'No Tags') AS RecommendedTag,
    UES.UniqueEditors,
    UES.CollaborationLevel
FROM 
    PostAnalytics PA
LEFT JOIN 
    PostRecommendations PR ON PA.PostId = PR.PostId
JOIN 
    UniqueEditorStats UES ON PA.PostId = UES.PostId
WHERE 
    PA.CommentCount > 5
    AND PA.UpVoteCount > PA.DownVoteCount
    AND (PA.PostRank <= 5 OR UES.CollaborationLevel = 'Highly Collaborative')
ORDER BY 
    PA.CreationDate DESC,
    PA.UpVoteCount DESC
LIMIT 100;