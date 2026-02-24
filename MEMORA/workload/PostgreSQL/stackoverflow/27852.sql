
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS Author,
        COALESCE(COUNT(c.Id), 0) AS CommentCount, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags
), FilteredPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS ChangeDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastChangeDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 52, 53)  
), FinalResult AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Author,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        MAX(fph.ChangeDate) AS LastHistoryChange, 
        MAX(fph.LastChangeDate) AS LastChange
    FROM 
        RankedPosts rp
    LEFT JOIN 
        FilteredPostHistory fph ON rp.PostId = fph.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.Score, rp.Author, rp.CommentCount, rp.UpVotes, rp.DownVotes
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    ViewCount,
    Score,
    Author,
    CommentCount,
    UpVotes,
    DownVotes,
    LastHistoryChange,
    LastChange
FROM 
    FinalResult
WHERE 
    LastHistoryChange IS NOT NULL
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 10;
