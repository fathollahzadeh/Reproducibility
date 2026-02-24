WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
RecentPostHistory AS (
    SELECT
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.ScoreRank,
        COALESCE(rph.UserId, -1) AS RecentEditorId,
        COALESCE(rph.Comment, 'No recent changes') AS RecentComment,
        COALESCE(rph.HistoryCreationDate, '1970-01-01') AS LastEditedDate,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentPostHistory rph ON rp.PostId = rph.PostId AND rph.HistoryRank = 1
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.ScoreRank,
    ps.RecentEditorId,
    ps.RecentComment,
    ps.LastEditedDate,
    ps.CommentStatus,
    CASE 
        WHEN ps.Score IS NULL THEN 'No Score'
        WHEN ps.Score < 0 THEN 'Negative Score'
        WHEN ps.Score >50 THEN 'Popular'
        ELSE 'Average'
    END AS ScoreCategory
FROM 
    PostStatistics ps
WHERE 
    ps.ScoreRank <= 10
ORDER BY 
    ps.Score DESC NULLS LAST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;