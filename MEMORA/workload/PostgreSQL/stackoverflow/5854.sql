WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        COUNT(b.Id) AS BadgeCount,
        PARENT.Title AS ParentTitle,
        PARENT.Id AS ParentId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId 
    LEFT JOIN 
        Posts PARENT ON p.ParentId = PARENT.Id 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, PARENT.Title, PARENT.Id
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS HistoryCount,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CommentCount,
    pm.UpVoteCount,
    pm.DownVoteCount,
    pm.BadgeCount,
    COALESCE(pdh.HistoryCount, 0) AS HistoryCount,
    COALESCE(pdh.HistoryTypes, 'None') AS HistoryTypes,
    pm.ParentId,
    pm.ParentTitle
FROM 
    PostMetrics pm
LEFT JOIN 
    PostHistoryDetails pdh ON pm.PostId = pdh.PostId
ORDER BY 
    pm.CommentCount DESC, 
    pm.UpVoteCount DESC
LIMIT 100;