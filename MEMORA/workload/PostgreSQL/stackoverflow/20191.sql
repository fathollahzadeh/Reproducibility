WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.Reputation AS UserReputation,
        PH.CreationDate AS PostCreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (1, 2, 4, 10) 
    WHERE 
        P.PostTypeId = 1 
        AND P.Score IS NOT NULL
        AND U.Reputation > 100 
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.UserReputation,
        RP.PostCreationDate,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS UpVoteCount,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS DownVoteCount,
        COALESCE(MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END), '1900-01-01') AS ClosedDate,
        COALESCE(MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN PH.CreationDate END), '1900-01-01') AS ReopenedDate
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Votes V ON RP.PostId = V.PostId
    LEFT JOIN 
        PostHistory PH ON RP.PostId = PH.PostId
    GROUP BY 
        RP.PostId, RP.Title, RP.UserReputation, RP.PostCreationDate
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.UserReputation,
    PD.PostCreationDate,
    PD.UpVoteCount - PD.DownVoteCount AS NetVoteCount,
    CASE 
        WHEN PD.ClosedDate < PD.ReopenedDate THEN 'Open' 
        ELSE 'Closed' 
    END AS PostStatus,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PD.PostId) AS CommentCount,
    (SELECT STRING_AGG(T.TagName, ', ') FROM Tags T 
     JOIN Posts PS ON PS.Tags LIKE '%' || T.TagName || '%' 
     WHERE PS.Id = PD.PostId) AS AssociatedTags
FROM 
    PostDetails PD
WHERE 
    PD.UserReputation > 200
    AND PD.PostCreationDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
    AND (PD.UpVoteCount - PD.DownVoteCount) > 1
ORDER BY 
    PD.PostCreationDate DESC, 
    NetVoteCount DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;