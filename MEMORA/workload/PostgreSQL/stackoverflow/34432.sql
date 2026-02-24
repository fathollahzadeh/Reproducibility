
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
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
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
PostSummary AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        ra.CommentCount,
        ra.UpVotes,
        ra.DownVotes,
        COALESCE(pd.LastEditDate, rp.CreationDate) AS LastActiveDate,
        rp.ScoreRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON rp.Id = ra.PostId
    LEFT JOIN 
        PostHistoryDetails pd ON rp.Id = pd.PostId
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.LastActiveDate,
    CASE 
        WHEN ps.ScoreRank <= 10 THEN 'Top 10 in Category'
        ELSE 'Other'
    END AS ScoreCategory
FROM 
    PostSummary ps
WHERE 
    ps.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
