
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostTypeRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),

FilteredPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
        AND ph.UserId IS NOT NULL
),

AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE 
            WHEN vt.Name = 'UpMod' THEN 1 
            WHEN vt.Name = 'DownMod' THEN -1 
            ELSE 0 
        END) AS VoteScore,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),

FinalResults AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.OwnerDisplayName,
        COALESCE(av.VoteScore, 0) AS NetVotes,
        COALESCE(av.VoteCount, 0) AS TotalVotes,
        r.CommentCount,
        ph.HistoryDate,
        ph.UserDisplayName AS EditorName,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted'
            ELSE 'Other'
        END AS HistoryAction
    FROM 
        RankedPosts r
    LEFT JOIN 
        FilteredPostHistory ph ON r.PostId = ph.PostId
    LEFT JOIN 
        AggregatedVotes av ON r.PostId = av.PostId
    WHERE 
        r.PostTypeRank <= 5 
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.OwnerDisplayName,
    fr.NetVotes,
    fr.TotalVotes,
    fr.CommentCount,
    MAX(fr.HistoryDate) AS LastHistoryDate,
    STRING_AGG(fr.HistoryAction, ', ') AS Actions,
    CASE 
        WHEN COUNT(DISTINCT ph.UserDisplayName) > 0 THEN 'Has Editors'
        ELSE 'No Editors'
    END AS EditorStatus
FROM 
    FinalResults fr
LEFT JOIN 
    FilteredPostHistory ph ON fr.PostId = ph.PostId
GROUP BY 
    fr.PostId, fr.Title, fr.CreationDate, fr.OwnerDisplayName, fr.NetVotes, fr.TotalVotes, fr.CommentCount
ORDER BY 
    fr.CreationDate DESC;
