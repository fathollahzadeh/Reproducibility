WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Ranking
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Body,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Ranking <= 5
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
),
PostCommentSummary AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        ph.PostId
),
FinalPostReport AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Body,
        tp.ViewCount,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        COALESCE(cs.CommentCount, 0) AS CommentCount,
        COALESCE(phs.EditCount, 0) AS EditCount,
        phs.LastEditDate,
        phs.EditTypes
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVoteSummary pvs ON tp.PostId = pvs.PostId
    LEFT JOIN 
        PostCommentSummary cs ON tp.PostId = cs.PostId
    LEFT JOIN 
        PostHistorySummary phs ON tp.PostId = phs.PostId
)
SELECT 
    fpr.PostId,
    fpr.Title,
    fpr.CreationDate,
    fpr.Body,
    fpr.ViewCount,
    fpr.UpVotes,
    fpr.DownVotes,
    fpr.CommentCount,
    fpr.EditCount,
    fpr.LastEditDate,
    fpr.EditTypes,
    CASE 
        WHEN fpr.UpVotes > fpr.DownVotes THEN 'Positive'
        WHEN fpr.UpVotes < fpr.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    FinalPostReport fpr
ORDER BY 
    fpr.ViewCount DESC, fpr.LastEditDate DESC;