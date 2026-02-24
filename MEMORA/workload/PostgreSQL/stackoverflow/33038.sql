
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVotes,
        SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24, 19) THEN 1 END) AS EditHistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    ui.UpVotes,
    ui.DownVotes,
    ph.CloseCount,
    ph.ReopenCount,
    ph.EditHistoryCount,
    CASE 
        WHEN ph.CloseCount > 0 THEN 'Closed'
        WHEN ph.ReopenCount > 0 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    STRING_AGG(DISTINCT b.Name, ', ') AS Badges
FROM 
    RankedPosts rp
LEFT JOIN 
    UserInteractions ui ON ui.UserId = rp.Id
LEFT JOIN 
    PostHistoryStats ph ON ph.PostId = rp.Id
LEFT JOIN 
    Badges b ON b.UserId = rp.Id
WHERE 
    rp.Rank <= 10 
GROUP BY 
    rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, 
    rp.CommentCount, ui.UpVotes, ui.DownVotes, 
    ph.CloseCount, ph.ReopenCount, ph.EditHistoryCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
